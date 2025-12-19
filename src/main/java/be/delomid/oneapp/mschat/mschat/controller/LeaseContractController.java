package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.service.LeaseContractService;
import be.delomid.oneapp.mschat.mschat.util.SecurityContextUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/lease-contracts")
@RequiredArgsConstructor
@Tag(name = "Lease Contract Management")
public class LeaseContractController {

    private final LeaseContractService leaseContractService;

    @PostMapping
    @Operation(summary = "Create a new lease contract")
    public ResponseEntity<LeaseContractDto> createContract(@RequestBody CreateLeaseContractRequest request) {
        LeaseContractDto contract = leaseContractService.createContract(request);
        return ResponseEntity.ok(contract);
    }

    @GetMapping("/{contractId}")
    @Operation(summary = "Get contract by ID")
    public ResponseEntity<LeaseContractDto> getContract(@PathVariable UUID contractId) {
        LeaseContractDto contract = leaseContractService.getContractById(contractId);
        return ResponseEntity.ok(contract);
    }

    @GetMapping("/owner/{ownerId}")
    @Operation(summary = "Get all contracts for an owner")
    public ResponseEntity<List<LeaseContractDto>> getContractsByOwner(@PathVariable String ownerId) {
        List<LeaseContractDto> contracts = leaseContractService.getContractsByOwner(ownerId);
        return ResponseEntity.ok(contracts);
    }

    @GetMapping("/tenant/{tenantId}")
    @Operation(summary = "Get all contracts for a tenant")
    public ResponseEntity<List<LeaseContractDto>> getContractsByTenant(@PathVariable String tenantId) {
        List<LeaseContractDto> contracts = leaseContractService.getContractsByTenant(tenantId);
        return ResponseEntity.ok(contracts);
    }

    @GetMapping("/my-contracts")
    @Operation(summary = "Get current user's contracts")
    public ResponseEntity<List<LeaseContractDto>> getMyContracts() {
        String userId = SecurityContextUtil.getCurrentUserId();
        List<LeaseContractDto> ownerContracts = leaseContractService.getContractsByOwner(userId);
        List<LeaseContractDto> tenantContracts = leaseContractService.getContractsByTenant(userId);
        ownerContracts.addAll(tenantContracts);
        return ResponseEntity.ok(ownerContracts);
    }

    @PostMapping("/{contractId}/sign-owner")
    @Operation(summary = "Owner signs the contract")
    public ResponseEntity<LeaseContractDto> signByOwner(
            @PathVariable UUID contractId,
            @RequestBody SignatureRequest request) {
        LeaseContractDto contract = leaseContractService.signContractByOwner(contractId, request.getSignatureData());
        return ResponseEntity.ok(contract);
    }

    @PostMapping("/{contractId}/sign-tenant")
    @Operation(summary = "Tenant signs the contract")
    public ResponseEntity<LeaseContractDto> signByTenant(
            @PathVariable UUID contractId,
            @RequestBody SignatureRequest request) {
        LeaseContractDto contract = leaseContractService.signContractByTenant(contractId, request.getSignatureData());
        return ResponseEntity.ok(contract);
    }

    @PostMapping("/{contractId}/index-rent")
    @Operation(summary = "Index the rent")
    public ResponseEntity<RentIndexationDto> indexRent(
            @PathVariable UUID contractId,
            @RequestParam BigDecimal indexationRate,
            @RequestParam(required = false) BigDecimal baseIndex,
            @RequestParam(required = false) BigDecimal newIndex,
            @RequestParam(required = false) String notes) {
        RentIndexationDto indexation = leaseContractService.indexRent(contractId, indexationRate, baseIndex, newIndex, notes);
        return ResponseEntity.ok(indexation);
    }
}
