package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateRoomFieldValueRequest {
    private Long fieldDefinitionId;
    private String textValue;
    private BigDecimal numberValue;
    private Boolean booleanValue;
}
