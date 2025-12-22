package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateCustomFieldRequest {
    private String fieldLabel;
    private String fieldValue;
    private Boolean isSystemField;
}
