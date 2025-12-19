package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.ApartmentDto;
import be.delomid.oneapp.mschat.mschat.dto.CreateOwnerRequest;
import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
import be.delomid.oneapp.mschat.mschat.service.OwnerService;
import be.delomid.oneapp.mschat.mschat.util.SecurityContextUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/owners")
@RequiredArgsConstructor
@Tag(name = "Owner Management")
public class OwnerController {

    private final OwnerService ownerService;

    @PostMapping
    @Operation(summary = "Create a new owner")
    public ResponseEntity<ResidentDto> createOwner(@RequestBody CreateOwnerRequest request) {
        String creatorId = SecurityContextUtil.getCurrentUserId();
        ResidentDto owner = ownerService.createOwner(request, creatorId);
        return ResponseEntity.ok(owner);
    }

    @GetMapping("/building/{buildingId}")
    @Operation(summary = "Get all owners for a building")
    public ResponseEntity<List<ResidentDto>> getOwnersByBuilding(@PathVariable String buildingId) {
        List<ResidentDto> owners = ownerService.getOwnersByBuilding(buildingId);
        return ResponseEntity.ok(owners);
    }

    @PutMapping("/assign-apartment")
    @Operation(summary = "Assign apartment to owner")
    public ResponseEntity<Void> assignApartmentToOwner(
            @RequestParam String apartmentId,
            @RequestParam String ownerId) {
        String adminId = SecurityContextUtil.getCurrentUserId();
        ownerService.assignApartmentToOwner(apartmentId, ownerId, adminId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/my-properties")
    @Operation(summary = "Get my owned apartments in the current building")
    public ResponseEntity<List<ApartmentDto>> getMyOwnedApartments(@RequestParam String buildingId) {
        String userId = SecurityContextUtil.getCurrentUserId();
        List<ApartmentDto> apartments = ownerService.getMyOwnedApartments(userId, buildingId);
        return ResponseEntity.ok(apartments);
    }
}
