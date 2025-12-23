package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.service.ApartmentManagementService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/apartment-management")
@RequiredArgsConstructor
@Tag(name = "Apartment Management", description = "Dynamic apartment management with rooms and custom fields")
@SecurityRequirement(name = "bearer-jwt")
public class ApartmentManagementController {

    private final ApartmentManagementService apartmentManagementService;

    @PostMapping("/apartments")
    @Operation(summary = "Create apartment with rooms and custom fields")
    public ResponseEntity<ApartmentCompleteDto> createApartment(
            @RequestBody CreateApartmentWithRoomsRequest request) {
        ApartmentCompleteDto result = apartmentManagementService.createApartmentWithRooms(request);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/apartments/{apartmentId}")
    @Operation(summary = "Get complete apartment details")
    public ResponseEntity<ApartmentCompleteDto> getApartment(@PathVariable String apartmentId) {
        ApartmentCompleteDto result = apartmentManagementService.getApartmentComplete(apartmentId);
        return ResponseEntity.ok(result);
    }

    @PutMapping("/apartments/{apartmentId}/rooms")
    @Operation(summary = "Update apartment rooms")
    public ResponseEntity<ApartmentCompleteDto> updateRooms(
            @PathVariable String apartmentId,
            @RequestBody List<CreateRoomRequest> roomsRequest) {
        ApartmentCompleteDto result = apartmentManagementService.updateApartmentRooms(apartmentId, roomsRequest);
        return ResponseEntity.ok(result);
    }

    @PutMapping("/apartments/{apartmentId}/custom-fields")
    @Operation(summary = "Update apartment custom fields")
    public ResponseEntity<ApartmentCompleteDto> updateCustomFields(
            @PathVariable String apartmentId,
            @RequestBody List<CreateCustomFieldRequest> customFieldsRequest) {
        ApartmentCompleteDto result = apartmentManagementService.updateCustomFields(apartmentId, customFieldsRequest);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/room-types")
    @Operation(summary = "Get all system room types")
    public ResponseEntity<List<RoomTypeDto>> getSystemRoomTypes() {
        List<RoomTypeDto> result = apartmentManagementService.getSystemRoomTypes();
        return ResponseEntity.ok(result);
    }

    @GetMapping("/room-types/{buildingId}")
    @Operation(summary = "Get room types for a building (including system types)")
    public ResponseEntity<List<RoomTypeDto>> getRoomTypes(@PathVariable String buildingId) {
        List<RoomTypeDto> result = apartmentManagementService.getRoomTypes(buildingId);
        return ResponseEntity.ok(result);
    }
}
