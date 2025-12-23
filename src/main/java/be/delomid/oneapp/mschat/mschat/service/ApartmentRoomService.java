package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ApartmentRoomService {

    private final ApartmentRoomRepository apartmentRoomRepository;
    private final RoomImageRepository roomImageRepository;
    private final ApartmentRepository apartmentRepository;
    private final RoomTypeRepository roomTypeRepository;
    private final RoomEquipmentRepository roomEquipmentRepository;

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

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

    public List<RoomTypeDto> getAllRoomTypes() {
        return roomTypeRepository.findAll().stream()
                .map(this::convertRoomTypeToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public Map<String, Object> createRoomWithEquipments(CreateRoomWithEquipmentsRequest request) {
        Apartment apartment = apartmentRepository.findById(String.valueOf(request.getApartmentId()))
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        RoomType roomType = roomTypeRepository.findById(request.getRoomTypeId())
                .orElseThrow(() -> new RuntimeException("RoomType not found"));

        ApartmentRoom room = ApartmentRoom.builder()
                .apartment(apartment)
                .roomName(request.getRoomName())
                .roomType(roomType)
                .orderIndex(0)
                .build();

        room = apartmentRoomRepository.save(room);

        List<Map<String, Object>> equipmentsList = new ArrayList<>();
        if (request.getEquipments() != null) {
            for (CreateRoomWithEquipmentsRequest.EquipmentData equipmentData : request.getEquipments()) {
                RoomEquipment equipment = RoomEquipment.builder()
                        .apartmentRoom(room)
                        .name(equipmentData.getName())
                        .description(equipmentData.getDescription())
                        .build();

                equipment = roomEquipmentRepository.save(equipment);

                Map<String, Object> equipmentMap = new HashMap<>();
                equipmentMap.put("id", equipment.getId());
                equipmentMap.put("name", equipment.getName());
                equipmentMap.put("description", equipment.getDescription());
                equipmentsList.add(equipmentMap);
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("id", room.getId());
        result.put("roomName", room.getRoomName());
        result.put("apartmentId", room.getApartment().getIdApartment());
        result.put("roomTypeId", room.getRoomType().getId());
        result.put("equipments", equipmentsList);

        return result;
    }

    @Transactional
    public RoomImageDto uploadEquipmentImage(Long equipmentId, MultipartFile file) {
        RoomEquipment equipment = roomEquipmentRepository.findById(equipmentId)
                .orElseThrow(() -> new RuntimeException("Equipment not found"));

        try {
            String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename();
            Path uploadPath = Paths.get(uploadDir, "equipment-images");

            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            Path filePath = uploadPath.resolve(fileName);
            Files.copy(file.getInputStream(), filePath);

            String imageUrl = "/uploads/equipment-images/" + fileName;

            RoomImage roomImage = RoomImage.builder()
                    .equipment(equipment)
                    .imageUrl(imageUrl)
                    .displayOrder(0)
                    .build();

            roomImage = roomImageRepository.save(roomImage);

            return convertToRoomImageDto(roomImage);
        } catch (IOException e) {
            throw new RuntimeException("Failed to upload image: " + e.getMessage());
        }
    }

    private RoomImageDto convertToRoomImageDto(RoomImage image) {
        return RoomImageDto.builder()
                .id(image.getId())
                .imageUrl(image.getImageUrl())
                .apartmentRoomId(image.getApartmentRoom() != null ? image.getApartmentRoom().getId() : null)
                .equipmentId(image.getEquipment() != null ? image.getEquipment().getId() : null)
                .displayOrder(image.getDisplayOrder())
                .build();
    }

    private RoomTypeDto convertRoomTypeToDto(RoomType roomType) {
        return RoomTypeDto.builder()
                .id(roomType.getId())
                .name(roomType.getName())
                .description(roomType.getDescription())
                .icon(roomType.getIcon())
                .build();
    }
}
