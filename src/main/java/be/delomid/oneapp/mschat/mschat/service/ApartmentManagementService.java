package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ApartmentManagementService {

    private final ApartmentRepository apartmentRepository;
    private final BuildingRepository buildingRepository;
    private final ResidentRepository residentRepository;
    private final RoomTypeRepository roomTypeRepository;
    private final RoomTypeFieldDefinitionRepository roomTypeFieldDefinitionRepository;
    private final ApartmentRoomNewRepository apartmentRoomNewRepository;
    private final RoomFieldValueRepository roomFieldValueRepository;
    private final RoomEquipmentRepository roomEquipmentRepository;
    private final RoomImageRepository roomImageRepository;
    private final ApartmentCustomFieldRepository apartmentCustomFieldRepository;

    @Transactional
    public ApartmentCompleteDto createApartmentWithRooms(CreateApartmentWithRoomsRequest request) {
        Building building = buildingRepository.findById(request.getBuildingId())
                .orElseThrow(() -> new RuntimeException("Building not found"));

        if (request.getFloor() > building.getMaxFloors()) {
            throw new RuntimeException("Floor number exceeds building max floors");
        }

        Apartment apartment = new Apartment();
        apartment.setPropertyName(request.getPropertyName());
        apartment.setNumber(request.getNumber());
        apartment.setFloor(request.getFloor());
        apartment.setOwnerId(request.getOwnerId());
        apartment.setBuildingId(request.getBuildingId());
        apartment = apartmentRepository.save(apartment);

        List<ApartmentRoom> savedRooms = new ArrayList<>();
        for (CreateRoomRequest roomRequest : request.getRooms()) {
            ApartmentRoom room = new ApartmentRoom();
            room.setApartmentId(apartment.getId());

            RoomType roomType = roomTypeRepository.findById(roomRequest.getRoomTypeId())
                    .orElseThrow(() -> new RuntimeException("Room type not found"));
            room.setRoomType(roomType);
            room.setRoomName(roomRequest.getRoomName());
            room = apartmentRoomNewRepository.save(room);

            for (CreateRoomFieldValueRequest fieldValueRequest : roomRequest.getFieldValues()) {
                RoomFieldValue fieldValue = new RoomFieldValue();
                fieldValue.setApartmentRoom(room);

                RoomTypeFieldDefinition fieldDef = roomTypeFieldDefinitionRepository.findById(fieldValueRequest.getFieldDefinitionId())
                        .orElseThrow(() -> new RuntimeException("Field definition not found"));
                fieldValue.setFieldDefinition(fieldDef);
                fieldValue.setTextValue(fieldValueRequest.getTextValue());
                fieldValue.setNumberValue(fieldValueRequest.getNumberValue());
                fieldValue.setBooleanValue(fieldValueRequest.getBooleanValue());
                roomFieldValueRepository.save(fieldValue);
            }

            for (CreateRoomEquipmentRequest equipmentRequest : roomRequest.getEquipments()) {
                RoomEquipment equipment = new RoomEquipment();
                equipment.setApartmentRoom(room);
                equipment.setName(equipmentRequest.getName());
                equipment.setDescription(equipmentRequest.getDescription());
                equipment = roomEquipmentRepository.save(equipment);

                int displayOrder = 0;
                for (String imageUrl : equipmentRequest.getImageUrls()) {
                    RoomImage image = new RoomImage();
                    image.setEquipment(equipment);
                    image.setImageUrl(imageUrl);
                    image.setDisplayOrder(displayOrder++);
                    roomImageRepository.save(image);
                }
            }

            int displayOrder = 0;
            for (String imageUrl : roomRequest.getImageUrls()) {
                RoomImage image = new RoomImage();
                image.setApartmentRoom(room);
                image.setImageUrl(imageUrl);
                image.setDisplayOrder(displayOrder++);
                roomImageRepository.save(image);
            }

            savedRooms.add(room);
        }

        int displayOrder = 0;
        for (CreateCustomFieldRequest customFieldRequest : request.getCustomFields()) {
            ApartmentCustomField customField = new ApartmentCustomField();
            customField.setApartmentId(apartment.getId());
            customField.setFieldLabel(customFieldRequest.getFieldLabel());
            customField.setFieldValue(customFieldRequest.getFieldValue());
            customField.setIsSystemField(customFieldRequest.getIsSystemField() != null ? customFieldRequest.getIsSystemField() : false);
            customField.setDisplayOrder(displayOrder++);
            apartmentCustomFieldRepository.save(customField);
        }

        return getApartmentComplete(apartment.getId());
    }

    @Transactional(readOnly = true)
    public ApartmentCompleteDto getApartmentComplete(Long apartmentId) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        ApartmentCompleteDto dto = new ApartmentCompleteDto();
        dto.setId(apartment.getId());
        dto.setPropertyName(apartment.getPropertyName());
        dto.setNumber(apartment.getNumber());
        dto.setFloor(apartment.getFloor());
        dto.setOwnerId(apartment.getOwnerId());
        dto.setBuildingId(apartment.getBuildingId());

        if (apartment.getOwnerId() != null) {
            residentRepository.findById(apartment.getOwnerId())
                    .ifPresent(owner -> dto.setOwnerName(owner.getFirstName() + " " + owner.getLastName()));
        }

        buildingRepository.findById(apartment.getBuildingId())
                .ifPresent(building -> dto.setBuildingName(building.getName()));

        List<ApartmentRoom> rooms = apartmentRoomNewRepository.findByApartmentIdOrderById(apartmentId);
        dto.setRooms(rooms.stream().map(this::convertToCompleteDto).collect(Collectors.toList()));

        List<ApartmentCustomField> customFields = apartmentCustomFieldRepository.findByApartmentIdOrderByDisplayOrder(apartmentId);
        dto.setCustomFields(customFields.stream().map(this::convertToDto).collect(Collectors.toList()));

        return dto;
    }

    @Transactional(readOnly = true)
    public List<RoomTypeDto> getRoomTypes(Long buildingId) {
        List<RoomType> roomTypes = roomTypeRepository.findByBuildingIdOrBuildingIdIsNull(buildingId);
        return roomTypes.stream().map(this::convertToDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<RoomTypeDto> getSystemRoomTypes() {
        List<RoomType> roomTypes = roomTypeRepository.findByBuildingIdIsNull();
        return roomTypes.stream().map(this::convertToDto).collect(Collectors.toList());
    }

    @Transactional
    public ApartmentCompleteDto updateApartmentRooms(Long apartmentId, List<CreateRoomRequest> roomsRequest) {
        apartmentRoomNewRepository.deleteAll(apartmentRoomNewRepository.findByApartmentIdOrderById(apartmentId));

        for (CreateRoomRequest roomRequest : roomsRequest) {
            ApartmentRoom room = new ApartmentRoom();
            room.setApartmentId(apartmentId);

            RoomType roomType = roomTypeRepository.findById(roomRequest.getRoomTypeId())
                    .orElseThrow(() -> new RuntimeException("Room type not found"));
            room.setRoomType(roomType);
            room.setRoomName(roomRequest.getRoomName());
            room = apartmentRoomNewRepository.save(room);

            for (CreateRoomFieldValueRequest fieldValueRequest : roomRequest.getFieldValues()) {
                RoomFieldValue fieldValue = new RoomFieldValue();
                fieldValue.setApartmentRoom(room);

                RoomTypeFieldDefinition fieldDef = roomTypeFieldDefinitionRepository.findById(fieldValueRequest.getFieldDefinitionId())
                        .orElseThrow(() -> new RuntimeException("Field definition not found"));
                fieldValue.setFieldDefinition(fieldDef);
                fieldValue.setTextValue(fieldValueRequest.getTextValue());
                fieldValue.setNumberValue(fieldValueRequest.getNumberValue());
                fieldValue.setBooleanValue(fieldValueRequest.getBooleanValue());
                roomFieldValueRepository.save(fieldValue);
            }

            for (CreateRoomEquipmentRequest equipmentRequest : roomRequest.getEquipments()) {
                RoomEquipment equipment = new RoomEquipment();
                equipment.setApartmentRoom(room);
                equipment.setName(equipmentRequest.getName());
                equipment.setDescription(equipmentRequest.getDescription());
                equipment = roomEquipmentRepository.save(equipment);

                int displayOrder = 0;
                for (String imageUrl : equipmentRequest.getImageUrls()) {
                    RoomImage image = new RoomImage();
                    image.setEquipment(equipment);
                    image.setImageUrl(imageUrl);
                    image.setDisplayOrder(displayOrder++);
                    roomImageRepository.save(image);
                }
            }

            int displayOrder = 0;
            for (String imageUrl : roomRequest.getImageUrls()) {
                RoomImage image = new RoomImage();
                image.setApartmentRoom(room);
                image.setImageUrl(imageUrl);
                image.setDisplayOrder(displayOrder++);
                roomImageRepository.save(image);
            }
        }

        return getApartmentComplete(apartmentId);
    }

    @Transactional
    public ApartmentCompleteDto updateCustomFields(Long apartmentId, List<CreateCustomFieldRequest> customFieldsRequest) {
        apartmentCustomFieldRepository.deleteAll(apartmentCustomFieldRepository.findByApartmentIdOrderByDisplayOrder(apartmentId));

        int displayOrder = 0;
        for (CreateCustomFieldRequest customFieldRequest : customFieldsRequest) {
            ApartmentCustomField customField = new ApartmentCustomField();
            customField.setApartmentId(apartmentId);
            customField.setFieldLabel(customFieldRequest.getFieldLabel());
            customField.setFieldValue(customFieldRequest.getFieldValue());
            customField.setIsSystemField(customFieldRequest.getIsSystemField() != null ? customFieldRequest.getIsSystemField() : false);
            customField.setDisplayOrder(displayOrder++);
            apartmentCustomFieldRepository.save(customField);
        }

        return getApartmentComplete(apartmentId);
    }

    private RoomTypeDto convertToDto(RoomType roomType) {
        RoomTypeDto dto = new RoomTypeDto();
        dto.setId(roomType.getId());
        dto.setName(roomType.getName());
        dto.setBuildingId(roomType.getBuildingId());

        List<RoomTypeFieldDefinition> fieldDefs = roomTypeFieldDefinitionRepository.findByRoomTypeIdOrderByDisplayOrder(roomType.getId());
        dto.setFieldDefinitions(fieldDefs.stream().map(this::convertToDto).collect(Collectors.toList()));

        return dto;
    }

    private RoomTypeFieldDefinitionDto convertToDto(RoomTypeFieldDefinition fieldDef) {
        RoomTypeFieldDefinitionDto dto = new RoomTypeFieldDefinitionDto();
        dto.setId(fieldDef.getId());
        dto.setRoomTypeId(fieldDef.getRoomType().getId());
        dto.setFieldName(fieldDef.getFieldName());
        dto.setFieldType(fieldDef.getFieldType());
        dto.setIsRequired(fieldDef.getIsRequired());
        dto.setDisplayOrder(fieldDef.getDisplayOrder());
        return dto;
    }

    private ApartmentRoomCompleteDto convertToCompleteDto(ApartmentRoom room) {
        ApartmentRoomCompleteDto dto = new ApartmentRoomCompleteDto();
        dto.setId(room.getId());
        dto.setApartmentId(room.getApartmentId());
        dto.setRoomName(room.getRoomName());
        dto.setRoomType(convertToDto(room.getRoomType()));

        List<RoomFieldValue> fieldValues = roomFieldValueRepository.findByApartmentRoomId(room.getId());
        dto.setFieldValues(fieldValues.stream().map(this::convertToDto).collect(Collectors.toList()));

        List<RoomEquipment> equipments = roomEquipmentRepository.findByApartmentRoomId(room.getId());
        dto.setEquipments(equipments.stream().map(this::convertToDto).collect(Collectors.toList()));

        List<RoomImage> images = roomImageRepository.findByApartmentRoomIdOrderByDisplayOrder(room.getId());
        dto.setImages(images.stream().map(this::convertToDto).collect(Collectors.toList()));

        return dto;
    }

    private RoomFieldValueDto convertToDto(RoomFieldValue fieldValue) {
        RoomFieldValueDto dto = new RoomFieldValueDto();
        dto.setId(fieldValue.getId());
        dto.setApartmentRoomId(fieldValue.getApartmentRoom().getId());
        dto.setFieldDefinitionId(fieldValue.getFieldDefinition().getId());
        dto.setFieldName(fieldValue.getFieldDefinition().getFieldName());
        dto.setTextValue(fieldValue.getTextValue());
        dto.setNumberValue(fieldValue.getNumberValue());
        dto.setBooleanValue(fieldValue.getBooleanValue());
        return dto;
    }

    private RoomEquipmentDto convertToDto(RoomEquipment equipment) {
        RoomEquipmentDto dto = new RoomEquipmentDto();
        dto.setId(equipment.getId());
        dto.setApartmentRoomId(equipment.getApartmentRoom().getId());
        dto.setName(equipment.getName());
        dto.setDescription(equipment.getDescription());

        List<RoomImage> images = roomImageRepository.findByEquipmentIdOrderByDisplayOrder(equipment.getId());
        dto.setImages(images.stream().map(this::convertToDto).collect(Collectors.toList()));

        return dto;
    }

    private RoomImageDto convertToDto(RoomImage image) {
        RoomImageDto dto = new RoomImageDto();
        dto.setId(image.getId());
        dto.setApartmentRoomId(image.getApartmentRoom() != null ? image.getApartmentRoom().getId() : null);
        dto.setEquipmentId(image.getEquipment() != null ? image.getEquipment().getId() : null);
        dto.setImageUrl(image.getImageUrl());
        dto.setDisplayOrder(image.getDisplayOrder());
        return dto;
    }

    private ApartmentCustomFieldDto convertToDto(ApartmentCustomField customField) {
        ApartmentCustomFieldDto dto = new ApartmentCustomFieldDto();
        dto.setId(customField.getId());
        dto.setApartmentId(customField.getApartmentId());
        dto.setFieldLabel(customField.getFieldLabel());
        dto.setFieldValue(customField.getFieldValue());
        dto.setDisplayOrder(customField.getDisplayOrder());
        dto.setIsSystemField(customField.getIsSystemField());
        return dto;
    }
}
