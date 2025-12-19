package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.LeaseContractArticleDto;
import be.delomid.oneapp.mschat.mschat.dto.LeaseContractDto;
import be.delomid.oneapp.mschat.mschat.service.LeaseContractEnhancedService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/lease-contracts-enhanced")
@RequiredArgsConstructor
@Tag(name = "Enhanced Lease Contract Management")
public class LeaseContractEnhancedController {

    private final LeaseContractEnhancedService enhancedService;

    @GetMapping("/apartment/{apartmentId}/with-inventory-status")
    @Operation(summary = "Get all contracts for an apartment with inventory status")
    public ResponseEntity<List<LeaseContractDto>> getContractsByApartmentWithInventoryStatus(
            @PathVariable String apartmentId) {
        List<LeaseContractDto> contracts = enhancedService.getContractsByApartmentWithInventoryStatus(apartmentId);
        return ResponseEntity.ok(contracts);
    }

    @GetMapping("/standard-articles")
    @Operation(summary = "Get standard lease contract articles by region")
    public ResponseEntity<List<LeaseContractArticleDto>> getStandardArticles(
            @RequestParam String regionCode) {
        List<LeaseContractArticleDto> articles = enhancedService.getStandardArticles(regionCode);
        return ResponseEntity.ok(articles);
    }

    @GetMapping("/{contractId}/can-terminate")
    @Operation(summary = "Check if contract can be terminated")
    public ResponseEntity<Boolean> canTerminateContract(@PathVariable UUID contractId) {
        boolean canTerminate = enhancedService.canTerminateContract(contractId);
        return ResponseEntity.ok(canTerminate);
    }

    @GetMapping("/non-resident-users")
    @Operation(summary = "Get users who are not residents in any building")
    public ResponseEntity<List<Object>> getNonResidentUsers(
            @RequestParam(required = false) String search) {
        List<Object> users = enhancedService.getNonResidentUsers(search);
        return ResponseEntity.ok(users);
    }
}
