package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.CreateInventoryRequest;
import be.delomid.oneapp.mschat.mschat.dto.InventoryDto;
import be.delomid.oneapp.mschat.mschat.dto.InventoryRoomPhotoDto;
import be.delomid.oneapp.mschat.mschat.dto.SignatureRequest;
import be.delomid.oneapp.mschat.mschat.service.InventoryService;
import be.delomid.oneapp.mschat.mschat.service.PdfInventoryGenerationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/inventories")
@RequiredArgsConstructor
@Tag(name = "Inventory Management (État des lieux)")
public class InventoryController {

    private final InventoryService inventoryService;
    private final PdfInventoryGenerationService pdfInventoryGenerationService;

    @PostMapping
    @Operation(summary = "Create a new inventory")
    public ResponseEntity<InventoryDto> createInventory(@RequestBody CreateInventoryRequest request) {
        InventoryDto inventory = inventoryService.createInventory(request);
        return ResponseEntity.ok(inventory);
    }

    @GetMapping("/{inventoryId}")
    @Operation(summary = "Get inventory by ID")
    public ResponseEntity<InventoryDto> getInventory(@PathVariable UUID inventoryId) {
        InventoryDto inventory = inventoryService.getInventoryById(inventoryId);
        return ResponseEntity.ok(inventory);
    }

    @GetMapping("/contract/{contractId}")
    @Operation(summary = "Get all inventories for a contract")
    public ResponseEntity<List<InventoryDto>> getInventoriesByContract(@PathVariable UUID contractId) {
        List<InventoryDto> inventories = inventoryService.getInventoriesByContract(contractId);
        return ResponseEntity.ok(inventories);
    }

    @PutMapping("/{inventoryId}")
    @Operation(summary = "Update inventory")
    public ResponseEntity<InventoryDto> updateInventory(
            @PathVariable UUID inventoryId,
            @RequestBody InventoryDto dto) {
        InventoryDto inventory = inventoryService.updateInventory(inventoryId, dto);
        return ResponseEntity.ok(inventory);
    }

    @PostMapping("/{inventoryId}/sign-owner")
    @Operation(summary = "Owner signs the inventory")
    public ResponseEntity<InventoryDto> signByOwner(
            @PathVariable UUID inventoryId,
            @RequestBody SignatureRequest request) {
        InventoryDto inventory = inventoryService.signInventoryByOwner(inventoryId, request.getSignatureData());
        return ResponseEntity.ok(inventory);
    }

    @PostMapping("/{inventoryId}/sign-tenant")
    @Operation(summary = "Tenant signs the inventory")
    public ResponseEntity<InventoryDto> signByTenant(
            @PathVariable UUID inventoryId,
            @RequestBody SignatureRequest request) {
        InventoryDto inventory = inventoryService.signInventoryByTenant(inventoryId, request.getSignatureData());
        return ResponseEntity.ok(inventory);
    }

    @PostMapping("/{inventoryId}/generate-pdf")
    @Operation(summary = "Generate PDF for inventory")
    public ResponseEntity<Map<String, String>> generatePdf(@PathVariable UUID inventoryId) {
        try {
            String pdfPath = pdfInventoryGenerationService.generateInventoryPdf(inventoryId);
            return ResponseEntity.ok(Map.of("pdfUrl", pdfPath, "message", "PDF generated successfully"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to generate PDF: " + e.getMessage()));
        }
    }

    @PutMapping("/{inventoryId}/rooms/{roomEntryId}")
    @Operation(summary = "Update room entry description")
    public ResponseEntity<Map<String, String>> updateRoomDescription(
            @PathVariable UUID inventoryId,
            @PathVariable UUID roomEntryId,
            @RequestBody Map<String, String> body) {
        String description = body.get("description");
        inventoryService.updateRoomEntryDescription(inventoryId, roomEntryId, description);
        return ResponseEntity.ok(Map.of("message", "Room description updated successfully"));
    }

    @PostMapping("/{inventoryId}/rooms/{roomEntryId}/photos")
    @Operation(summary = "Upload photo for room entry")
    public ResponseEntity<InventoryRoomPhotoDto> uploadRoomPhoto(
            @PathVariable UUID inventoryId,
            @PathVariable UUID roomEntryId,
            @RequestParam("file") MultipartFile file) throws IOException {
        InventoryRoomPhotoDto photo = inventoryService.uploadRoomPhoto(inventoryId, roomEntryId, file);
        return ResponseEntity.ok(photo);
    }

    @GetMapping("/{inventoryId}/rooms/{roomEntryId}/photos")
    @Operation(summary = "Get photos for room entry")
    public ResponseEntity<List<InventoryRoomPhotoDto>> getRoomPhotos(
            @PathVariable UUID inventoryId,
            @PathVariable UUID roomEntryId) {
        List<InventoryRoomPhotoDto> photos = inventoryService.getRoomPhotos(inventoryId, roomEntryId);
        return ResponseEntity.ok(photos);
    }

    @DeleteMapping("/{inventoryId}/rooms/{roomEntryId}/photos/{photoId}")
    @Operation(summary = "Delete room photo")
    public ResponseEntity<Map<String, String>> deleteRoomPhoto(
            @PathVariable UUID inventoryId,
            @PathVariable UUID roomEntryId,
            @PathVariable UUID photoId) {
        inventoryService.deleteRoomPhoto(inventoryId, roomEntryId, photoId);
        return ResponseEntity.ok(Map.of("message", "Photo deleted successfully"));
    }
}
