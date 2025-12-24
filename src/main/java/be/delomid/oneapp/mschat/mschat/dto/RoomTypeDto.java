package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoomTypeDto {
    private Long id;
    private String name;
    private String buildingId;
    private String description;
    private String icon;
    private List<RoomTypeFieldDefinitionDto> fieldDefinitions = new ArrayList<>();
}
