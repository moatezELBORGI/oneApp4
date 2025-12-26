package be.delomid.oneapp.mschat.mschat.dto;

import lombok.Data;

@Data
public class UpdateApartmentBasicInfoRequest {
    private String propertyName;
    private String number;
    private Integer floor;
    private Double surface;
}
