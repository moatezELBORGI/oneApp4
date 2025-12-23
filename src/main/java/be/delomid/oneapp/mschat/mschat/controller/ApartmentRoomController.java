package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.service.ApartmentRoomService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/apartment-rooms")
@RequiredArgsConstructor
@Tag(name = "Apartment Room Management")
public class ApartmentRoomController {

    private final ApartmentRoomService apartmentRoomService;

    @PostMapping
    @Operation(summary = "Create a new room")
    public ResponseEntity<ApartmentRoomDto> createRoom(@RequestBody ApartmentRoomDto dto) {
        ApartmentRoomDto room = apartmentRoomService.createRoom(dto);
        return ResponseEntity.ok(room);
    }

    @GetMapping("/apartment/{apartmentId}")
    @Operation(summary = "Get all rooms for an apartment")
    public ResponseEntity<List<ApartmentRoomDto>> getRoomsByApartment(@PathVariable String apartmentId) {
        List<ApartmentRoomDto> rooms = apartmentRoomService.getRoomsByApartment(apartmentId);
        return ResponseEntity.ok(rooms);
    }

    @PutMapping("/{roomId}")
    @Operation(summary = "Update a room")
    public ResponseEntity<ApartmentRoomDto> updateRoom(
            @PathVariable Long roomId,
            @RequestBody ApartmentRoomDto dto) {
        ApartmentRoomDto room = apartmentRoomService.updateRoom(roomId, dto);
        return ResponseEntity.ok(room);
    }

    @DeleteMapping("/{roomId}")
    @Operation(summary = "Delete a room")
    public ResponseEntity<Void> deleteRoom(@PathVariable Long roomId) {
        apartmentRoomService.deleteRoom(roomId);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{roomId}/photos")
    @Operation(summary = "Add photo to room")
    public ResponseEntity<ApartmentRoomPhotoDto> addPhoto(
            @PathVariable Long roomId,
            @RequestParam String photoUrl,
            @RequestParam(required = false) String caption,
            @RequestParam(required = false) Integer orderIndex) {
        ApartmentRoomPhotoDto photo = apartmentRoomService.addPhotoToRoom(roomId, photoUrl, caption, orderIndex != null ? orderIndex : 0);
        return ResponseEntity.ok(photo);
    }

    @GetMapping("/room-types")
    @Operation(summary = "Get all room types")
    public ResponseEntity<List<RoomTypeDto>> getAllRoomTypes() {
        List<RoomTypeDto> roomTypes = apartmentRoomService.getAllRoomTypes();
        return ResponseEntity.ok(roomTypes);
    }

    @PostMapping("/with-equipments")
    @Operation(summary = "Create room with equipments")
    public ResponseEntity<Map<String, Object>> createRoomWithEquipments(
            @RequestBody CreateRoomWithEquipmentsRequest request) {
        Map<String, Object> result = apartmentRoomService.createRoomWithEquipments(request);
        return ResponseEntity.ok(result);
    }

    @PostMapping(value = "/equipments/{equipmentId}/upload-image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload equipment image")
    public ResponseEntity<RoomImageDto> uploadEquipmentImage(
            @PathVariable Long equipmentId,
            @RequestParam("file") MultipartFile file) {
        RoomImageDto image = apartmentRoomService.uploadEquipmentImage(equipmentId, file);
        return ResponseEntity.ok(image);
    }
}
