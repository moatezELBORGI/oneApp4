package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.ApartmentRoomDto;
import be.delomid.oneapp.mschat.mschat.dto.ApartmentRoomPhotoDto;
import be.delomid.oneapp.mschat.mschat.model.Apartment;
import be.delomid.oneapp.mschat.mschat.model.ApartmentRoom;
import be.delomid.oneapp.mschat.mschat.model.ApartmentRoomPhoto;
import be.delomid.oneapp.mschat.mschat.model.RoomType;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRepository;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRoomPhotoRepository;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRoomRepository;
import be.delomid.oneapp.mschat.mschat.repository.RoomTypeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ApartmentRoomService {

    private final ApartmentRoomRepository apartmentRoomRepository;
    private final ApartmentRoomPhotoRepository apartmentRoomPhotoRepository;
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
                .apartmentId(apartment.getIdApartment())
                .roomName(dto.getRoomName())
                .roomType(roomType)
                .description(dto.getDescription())
                .orderIndex(dto.getOrderIndex() != null ? dto.getOrderIndex() : 0)
                .build();

        room = apartmentRoomRepository.save(room);
        return convertToDto(room);
    }

    public List<ApartmentRoomDto> getRoomsByApartment(String apartmentId) {
        return apartmentRoomRepository.findByApartmentIdOrderById(apartmentId)
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

        ApartmentRoomPhoto photo = ApartmentRoomPhoto.builder()
                .room(room)
                .photoUrl(photoUrl)
                .caption(caption)
                .orderIndex(orderIndex)
                .build();

        photo = apartmentRoomPhotoRepository.save(photo);
        return convertPhotoToDto(photo);
    }

    private ApartmentRoomDto convertToDto(ApartmentRoom room) {
        List<ApartmentRoomPhotoDto> photos = apartmentRoomPhotoRepository.findByRoom_IdOrderByOrderIndex(room.getId())
                .stream()
                .map(this::convertPhotoToDto)
                .collect(Collectors.toList());

        return ApartmentRoomDto.builder()
                .id(room.getId().toString())
                .apartmentId(room.getApartmentId())
                .roomName(room.getRoomName())
                .roomType(room.getRoomType() != null ? room.getRoomType().getId().toString() : null)
                .description(room.getDescription())
                .orderIndex(room.getOrderIndex())
                .photos(photos)
                .createdAt(room.getCreatedAt())
                .updatedAt(room.getUpdatedAt())
                .build();
    }

    private ApartmentRoomPhotoDto convertPhotoToDto(ApartmentRoomPhoto photo) {
        return ApartmentRoomPhotoDto.builder()
                .id(photo.getId().toString())
                .roomId(photo.getRoom().getId().toString())
                .photoUrl(photo.getPhotoUrl())
                .caption(photo.getCaption())
                .orderIndex(photo.getOrderIndex())
                .createdAt(photo.getCreatedAt())
                .build();
    }
}
