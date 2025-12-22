package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentCustomFieldDto {
    private Long id;
    private String apartmentId;
    private String fieldLabel;
    private String fieldValue;
    private Integer displayOrder;
    private Boolean isSystemField;
}
