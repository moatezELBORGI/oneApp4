package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.EquipmentTemplateDto;
import be.delomid.oneapp.mschat.mschat.service.EquipmentTemplateService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/equipment-templates")
@RequiredArgsConstructor
@Tag(name = "Equipment Templates", description = "Manage predefined equipment templates for room types")
public class EquipmentTemplateController {

    private final EquipmentTemplateService equipmentTemplateService;

    @GetMapping
    @Operation(summary = "Get all active equipment templates")
    public ResponseEntity<List<EquipmentTemplateDto>> getAllTemplates() {
        return ResponseEntity.ok(equipmentTemplateService.getAllActiveTemplates());
    }

    @GetMapping("/room-type/{roomTypeId}")
    @Operation(summary = "Get equipment templates by room type")
    public ResponseEntity<List<EquipmentTemplateDto>> getTemplatesByRoomType(
            @PathVariable Long roomTypeId) {
        return ResponseEntity.ok(equipmentTemplateService.getTemplatesByRoomType(roomTypeId));
    }

    @PostMapping
    @Operation(summary = "Create new equipment template")
    public ResponseEntity<EquipmentTemplateDto> createTemplate(
            @RequestBody EquipmentTemplateDto dto) {
        return ResponseEntity.ok(equipmentTemplateService.createTemplate(dto));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update equipment template")
    public ResponseEntity<EquipmentTemplateDto> updateTemplate(
            @PathVariable Long id,
            @RequestBody EquipmentTemplateDto dto) {
        return ResponseEntity.ok(equipmentTemplateService.updateTemplate(id, dto));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete equipment template")
    public ResponseEntity<Void> deleteTemplate(@PathVariable Long id) {
        equipmentTemplateService.deleteTemplate(id);
        return ResponseEntity.noContent().build();
    }
}
