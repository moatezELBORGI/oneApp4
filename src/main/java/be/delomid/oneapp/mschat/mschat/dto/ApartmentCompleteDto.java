package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentCompleteDto {
    private String id;
    private String propertyName;
    private String number;
    private Integer floor;
    private String ownerId;
    private String ownerName;
    private String buildingId;
    private String buildingName;
    private List<ApartmentRoomCompleteDto> rooms = new ArrayList<>();
    private List<ApartmentCustomFieldDto> customFields = new ArrayList<>();
}
