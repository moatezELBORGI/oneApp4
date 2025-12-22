package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.FieldType;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RoomTypeFieldDefinitionDto {
    private Long id;
    private Long roomTypeId;
    private String fieldName;
    private FieldType fieldType;
    private Boolean isRequired;
    private Integer displayOrder;
}
