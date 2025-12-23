package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.ApartmentRoomDto;
import be.delomid.oneapp.mschat.mschat.dto.ApartmentRoomPhotoDto;
import be.delomid.oneapp.mschat.mschat.model.Apartment;
import be.delomid.oneapp.mschat.mschat.model.ApartmentRoom;
import be.delomid.oneapp.mschat.mschat.model.RoomImage;
import be.delomid.oneapp.mschat.mschat.model.RoomType;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRepository;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRoomRepository;
import be.delomid.oneapp.mschat.mschat.repository.RoomImageRepository;
import be.delomid.oneapp.mschat.mschat.repository.RoomTypeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ApartmentRoomService {

    private final ApartmentRoomRepository apartmentRoomRepository;
    private final RoomImageRepository roomImageRepository;
    private final ApartmentRepository apartmentRepository;
    private final RoomTypeRepository roomTypeRepository;

    @Transactional
    public ApartmentRoomDto createRoom(ApartmentRoomDto dto) {
        Apartment apartment = apartmentRepository.findById(dto.getApartmentId())
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        RoomType roomType = null;
        if (dto.getRoomType() != null) {
            try {
                Long roomTypeId = Long.parseLong(dto.getRoomType());
                roomType = roomTypeRepository.findById(roomTypeId)
                        .orElseThrow(() -> new RuntimeException("RoomType not found"));
            } catch (NumberFormatException e) {
                throw new RuntimeException("Invalid RoomType ID format");
            }
        }

        ApartmentRoom room = ApartmentRoom.builder()
                .apartment(apartment)
                .roomName(dto.getRoomName())
                .roomType(roomType)
                .description(dto.getDescription())
                .orderIndex(dto.getOrderIndex() != null ? dto.getOrderIndex() : 0)
                .build();

        room = apartmentRoomRepository.save(room);
        return convertToDto(room);
    }

    public List<ApartmentRoomDto> getRoomsByApartment(String apartmentId) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found"));
        return apartmentRoomRepository.findByApartmentOrderById(apartment)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public ApartmentRoomDto updateRoom(Long roomId, ApartmentRoomDto dto) {
        ApartmentRoom room = apartmentRoomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found"));

        if (dto.getRoomName() != null) {
            room.setRoomName(dto.getRoomName());
        }

        if (dto.getRoomType() != null) {
            try {
                Long roomTypeId = Long.parseLong(dto.getRoomType());
                RoomType roomType = roomTypeRepository.findById(roomTypeId)
                        .orElseThrow(() -> new RuntimeException("RoomType not found"));
                room.setRoomType(roomType);
            } catch (NumberFormatException e) {
                throw new RuntimeException("Invalid RoomType ID format");
            }
        }

        if (dto.getDescription() != null) {
            room.setDescription(dto.getDescription());
        }

        if (dto.getOrderIndex() != null) {
            room.setOrderIndex(dto.getOrderIndex());
        }

        room = apartmentRoomRepository.save(room);
        return convertToDto(room);
    }

    @Transactional
    public void deleteRoom(Long roomId) {
        apartmentRoomRepository.deleteById(roomId);
    }

    @Transactional
    public ApartmentRoomPhotoDto addPhotoToRoom(Long roomId, String photoUrl, String caption, Integer orderIndex) {
        ApartmentRoom room = apartmentRoomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found"));

        RoomImage image = RoomImage.builder()
                .apartmentRoom(room)
                .imageUrl(photoUrl)
                .displayOrder(orderIndex != null ? orderIndex : 0)
                .build();

        image = roomImageRepository.save(image);
        return convertImageToPhotoDto(image, caption);
    }

    private ApartmentRoomDto convertToDto(ApartmentRoom room) {
        List<ApartmentRoomPhotoDto> photos = new ArrayList<>();
        if (room.getImages() != null) {
            photos = room.getImages().stream()
                    .map(image -> convertImageToPhotoDto(image, null))
                    .collect(Collectors.toList());
        }

        return ApartmentRoomDto.builder()
                .id(room.getId().toString())
                .apartmentId(room.getApartment().getIdApartment())
                .roomName(room.getRoomName())
                .roomType(room.getRoomType() != null ? room.getRoomType().getId().toString() : null)
                .description(room.getDescription())
                .orderIndex(room.getOrderIndex())
                .photos(photos)
                .createdAt(room.getCreatedAt())
                .updatedAt(room.getUpdatedAt())
                .build();
    }

    private ApartmentRoomPhotoDto convertImageToPhotoDto(RoomImage image, String caption) {
        return ApartmentRoomPhotoDto.builder()
                .id(image.getId().toString())
                .roomId(image.getApartmentRoom() != null ? image.getApartmentRoom().getId().toString() : null)
                .photoUrl(image.getImageUrl())
                .caption(caption)
                .orderIndex(image.getDisplayOrder())
                .createdAt(image.getCreatedAt())
                .build();
    }
}
