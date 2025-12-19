package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentRoomDto {
    private String id;
    private String apartmentId;
    private String roomName;
    private String roomType;
    private String description;
    private Integer orderIndex;
    @Builder.Default
    private List<ApartmentRoomPhotoDto> photos = new ArrayList<>();
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
