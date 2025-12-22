package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.ApartmentRoomDto;
import be.delomid.oneapp.mschat.mschat.dto.ApartmentRoomPhotoDto;
import be.delomid.oneapp.mschat.mschat.model.Apartment;
import be.delomid.oneapp.mschat.mschat.model.ApartmentRoom;
import be.delomid.oneapp.mschat.mschat.model.ApartmentRoomPhoto;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRepository;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRoomPhotoRepository;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRoomRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ApartmentRoomService {

    private final ApartmentRoomRepository apartmentRoomRepository;
    private final ApartmentRoomPhotoRepository apartmentRoomPhotoRepository;
    private final ApartmentRepository apartmentRepository;

    @Transactional
    public ApartmentRoomDto createRoom(ApartmentRoomDto dto) {
        Apartment apartment = apartmentRepository.findById(dto.getApartmentId())
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        ApartmentRoom room = ApartmentRoom.builder()
                .apartmentId(apartment.getIdApartment())
                .roomName(dto.getRoomName())
                .roomType(dto.getRoomType())
                .description(dto.getDescription())
                .orderIndex(dto.getOrderIndex())
                .build();

        room = apartmentRoomRepository.save(room);
        return convertToDto(room);
    }

    public List<ApartmentRoomDto> getRoomsByApartment(String apartmentId) {
        return apartmentRoomRepository.findByApartment_IdApartmentOrderByOrderIndex(apartmentId)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public ApartmentRoomDto updateRoom(Long roomId, ApartmentRoomDto dto) {
        ApartmentRoom room = apartmentRoomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found"));

        room.setRoomName(dto.getRoomName());
        room.setRoomType(dto.getRoomType());
        room.setDescription(dto.getDescription());
        room.setOrderIndex(dto.getOrderIndex());

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
                .roomType(room.getRoomType())
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
