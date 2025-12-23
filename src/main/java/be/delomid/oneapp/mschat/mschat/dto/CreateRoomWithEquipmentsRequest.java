package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateRoomWithEquipmentsRequest {
    private Long apartmentId;
    private String roomName;
    private Long roomTypeId;
    private List<EquipmentData> equipments;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EquipmentData {
        private String name;
        private String description;
    }
}
