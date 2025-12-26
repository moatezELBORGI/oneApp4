package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateApartmentWithRoomsRequest {
    private String propertyName;
    private String number;
    private Integer floor;
    private BigDecimal surface;
    private String ownerId;
    private String buildingId;
    private List<CreateRoomRequest> rooms = new ArrayList<>();
    private List<CreateCustomFieldRequest> customFields = new ArrayList<>();
}
