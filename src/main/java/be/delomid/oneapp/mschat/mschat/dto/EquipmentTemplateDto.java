package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EquipmentTemplateDto {
    private Long id;
    private String name;
    private Long roomTypeId;
    private String description;
    private Integer displayOrder;
    private Boolean isActive;
}
