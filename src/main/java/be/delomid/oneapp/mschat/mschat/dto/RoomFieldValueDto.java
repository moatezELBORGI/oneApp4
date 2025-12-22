package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RoomFieldValueDto {
    private Long id;
    private Long apartmentRoomId;
    private Long fieldDefinitionId;
    private String fieldName;
    private String textValue;
    private BigDecimal numberValue;
    private Boolean booleanValue;
}
