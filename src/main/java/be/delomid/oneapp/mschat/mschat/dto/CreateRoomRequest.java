package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateRoomRequest {
    private Long roomTypeId;
    private String roomName;
    private List<CreateRoomFieldValueRequest> fieldValues = new ArrayList<>();
    private List<CreateRoomEquipmentRequest> equipments = new ArrayList<>();
    private List<String> imageUrls = new ArrayList<>();
}
