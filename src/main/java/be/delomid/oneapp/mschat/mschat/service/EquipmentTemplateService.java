package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.EquipmentTemplateDto;
import be.delomid.oneapp.mschat.mschat.model.EquipmentTemplate;
import be.delomid.oneapp.mschat.mschat.repository.EquipmentTemplateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EquipmentTemplateService {

    private final EquipmentTemplateRepository equipmentTemplateRepository;

    @Transactional(readOnly = true)
    public List<EquipmentTemplateDto> getAllActiveTemplates() {
        return equipmentTemplateRepository.findByIsActiveTrueOrderByRoomTypeIdAscDisplayOrderAsc()
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<EquipmentTemplateDto> getTemplatesByRoomType(Long roomTypeId) {
        return equipmentTemplateRepository.findByRoomTypeIdAndIsActiveOrderByDisplayOrder(roomTypeId, true)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public EquipmentTemplateDto createTemplate(EquipmentTemplateDto dto) {
        EquipmentTemplate template = new EquipmentTemplate();
        template.setName(dto.getName());
        template.setRoomTypeId(dto.getRoomTypeId());
        template.setDescription(dto.getDescription());
        template.setDisplayOrder(dto.getDisplayOrder());
        template.setIsActive(dto.getIsActive() != null ? dto.getIsActive() : true);

        template = equipmentTemplateRepository.save(template);
        return convertToDto(template);
    }

    @Transactional
    public EquipmentTemplateDto updateTemplate(Long id, EquipmentTemplateDto dto) {
        EquipmentTemplate template = equipmentTemplateRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Equipment template not found"));

        template.setName(dto.getName());
        template.setDescription(dto.getDescription());
        template.setDisplayOrder(dto.getDisplayOrder());
        template.setIsActive(dto.getIsActive());

        template = equipmentTemplateRepository.save(template);
        return convertToDto(template);
    }

    @Transactional
    public void deleteTemplate(Long id) {
        equipmentTemplateRepository.deleteById(id);
    }

    private EquipmentTemplateDto convertToDto(EquipmentTemplate template) {
        return new EquipmentTemplateDto(
                template.getId(),
                template.getName(),
                template.getRoomTypeId(),
                template.getDescription(),
                template.getDisplayOrder(),
                template.getIsActive()
        );
    }
}
