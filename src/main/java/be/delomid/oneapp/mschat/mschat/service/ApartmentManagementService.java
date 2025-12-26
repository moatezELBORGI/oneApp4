package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
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
    private final ApartmentRoomRepository apartmentRoomRepository;
    private final RoomFieldValueRepository roomFieldValueRepository;
    private final RoomEquipmentRepository roomEquipmentRepository;
    private final RoomImageRepository roomImageRepository;
    private final ApartmentCustomFieldRepository apartmentCustomFieldRepository;
    private final ApartmentGeneralInfoRepository apartmentGeneralInfoRepository;

    @Transactional
    public ApartmentCompleteDto createApartmentWithRooms(CreateApartmentWithRoomsRequest request) {
        Building building = buildingRepository.findById(request.getBuildingId())
                .orElseThrow(() -> new RuntimeException("Building not found"));

        if (request.getFloor() > building.getNumberOfFloors()) {
            throw new RuntimeException("Floor number exceeds building max floors");
        }

        Resident resident=residentRepository.findById(request.getOwnerId()).orElseThrow(() -> new RuntimeException("Owner not found"));

        Apartment apartment = new Apartment();
        String apartmentId=request.getBuildingId()+"-"+ LocalDate.now().getYear()+request.getNumber();
        apartment.setIdApartment(apartmentId);
        apartment.setApartmentLabel(request.getPropertyName());
        apartment.setApartmentNumber(request.getNumber());
        apartment.setApartmentFloor(request.getFloor());
        apartment.setOwner(resident);
        apartment.setBuilding(building);
        apartment = apartmentRepository.save(apartment);

        if (request.getSurface() != null || request.getFloor() != null) {
            ApartmentGeneralInfo generalInfo = new ApartmentGeneralInfo();
            generalInfo.setApartmentId(apartmentId);
            generalInfo.setSurface(request.getSurface());
            generalInfo.setEtage(request.getFloor());
            apartmentGeneralInfoRepository.save(generalInfo);
        }

        List<ApartmentRoom> savedRooms = new ArrayList<>();
        for (CreateRoomRequest roomRequest : request.getRooms()) {
            ApartmentRoom room = new ApartmentRoom();
            room.setApartment(apartment);

            RoomType roomType = roomTypeRepository.findById(roomRequest.getRoomTypeId())
                    .orElseThrow(() -> new RuntimeException("Room type not found"));
            room.setRoomType(roomType);
            room.setRoomName(roomRequest.getRoomName());
            room = apartmentRoomRepository.save(room);

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
            customField.setApartmentId(apartment.getIdApartment());
            customField.setFieldLabel(customFieldRequest.getFieldLabel());
            customField.setFieldValue(customFieldRequest.getFieldValue());
            customField.setIsSystemField(customFieldRequest.getIsSystemField() != null ? customFieldRequest.getIsSystemField() : false);
            customField.setDisplayOrder(displayOrder++);
            apartmentCustomFieldRepository.save(customField);
        }

        return getApartmentComplete(apartment.getIdApartment());
    }

    @Transactional(readOnly = true)
    public ApartmentCompleteDto getApartmentComplete(String apartmentId) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        ApartmentCompleteDto dto = new ApartmentCompleteDto();
        dto.setId(apartment.getIdApartment());
        dto.setPropertyName(apartment.getApartmentLabel());
        dto.setNumber(apartment.getApartmentNumber());
        dto.setFloor(apartment.getApartmentFloor());
        dto.setOwnerId(apartment.getOwner().getIdUsers());
        dto.setBuildingId(apartment.getBuilding().getBuildingId());

        if (apartment.getOwner().getIdUsers() != null) {
            residentRepository.findById(apartment.getOwner().getIdUsers())
                    .ifPresent(owner -> dto.setOwnerName(owner.getFname() + " " + owner.getLname()));
        }

        buildingRepository.findById(apartment.getBuilding().getBuildingId())
                .ifPresent(building -> dto.setBuildingName(building.getBuildingLabel()));

        List<ApartmentRoom> rooms = apartmentRoomRepository.findByApartmentOrderById(apartment);
        dto.setRooms(rooms.stream().map(this::convertToCompleteDto).collect(Collectors.toList()));

        List<ApartmentCustomField> customFields = apartmentCustomFieldRepository.findByApartmentIdOrderByDisplayOrder(apartmentId);
        dto.setCustomFields(customFields.stream().map(this::convertToDto).collect(Collectors.toList()));

        return dto;
    }

    @Transactional(readOnly = true)
    public List<RoomTypeDto> getRoomTypes(String buildingId) {
        List<RoomType> roomTypes = roomTypeRepository.findByBuildingIdOrBuildingIdIsNull(buildingId);
        return roomTypes.stream().map(this::convertToDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<RoomTypeDto> getSystemRoomTypes() {
        List<RoomType> roomTypes = roomTypeRepository.findByBuildingIdIsNull();
        return roomTypes.stream().map(this::convertToDto).collect(Collectors.toList());
    }

    @Transactional
    public ApartmentCompleteDto updateApartmentRooms(String apartmentId, List<CreateRoomRequest> roomsRequest) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found"));
        apartmentRoomRepository.deleteAll(apartmentRoomRepository.findByApartmentOrderById(apartment));

        for (CreateRoomRequest roomRequest : roomsRequest) {
            ApartmentRoom room = new ApartmentRoom();
            room.setApartment(apartment);

            RoomType roomType = roomTypeRepository.findById(roomRequest.getRoomTypeId())
                    .orElseThrow(() -> new RuntimeException("Room type not found"));
            room.setRoomType(roomType);
            room.setRoomName(roomRequest.getRoomName());
            room = apartmentRoomRepository.save(room);

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
    public ApartmentCompleteDto updateCustomFields(String apartmentId, List<CreateCustomFieldRequest> customFieldsRequest) {
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

    @Transactional
    public ApartmentCompleteDto updateBasicInfo(String apartmentId, UpdateApartmentBasicInfoRequest request) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        if (request.getPropertyName() != null) {
            apartment.setApartmentLabel(request.getPropertyName());
        }
        if (request.getNumber() != null) {
            apartment.setApartmentNumber(request.getNumber());
        }
        if (request.getFloor() != null) {
            apartment.setApartmentFloor(request.getFloor());
        }
        apartmentRepository.save(apartment);

        if (request.getSurface() != null || request.getFloor() != null) {
            ApartmentGeneralInfo generalInfo = apartmentGeneralInfoRepository.findById(Long.valueOf(apartmentId))
                    .orElse(new ApartmentGeneralInfo());
            generalInfo.setApartmentId(apartmentId);
            if (request.getSurface() != null) {
                generalInfo.setSurface(BigDecimal.valueOf(request.getSurface()));
            }
            if (request.getFloor() != null) {
                generalInfo.setEtage(request.getFloor());
            }
            apartmentGeneralInfoRepository.save(generalInfo);
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
        dto.setApartmentId(room.getApartment().getIdApartment());
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
