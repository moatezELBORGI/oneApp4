package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class InventoryService {

    private final InventoryRepository inventoryRepository;
    private final InventoryRoomEntryRepository roomEntryRepository;
    private final LeaseContractRepository leaseContractRepository;
    private final ApartmentRoomNewRepository apartmentRoomNewRepository;
    private final RoomImageRepository roomImageRepository;
    private final InventoryRoomPhotoRepository roomPhotoRepository;
    private final FileService fileService;

    @Transactional
    public InventoryDto createInventory(CreateInventoryRequest request) {
        LeaseContract contract = leaseContractRepository.findById(UUID.fromString(request.getContractId()))
                .orElseThrow(() -> new RuntimeException("Contract not found"));

        InventoryType type = InventoryType.valueOf(request.getType());

        Inventory inventory = Inventory.builder()
                .contract(contract)
                .type(type)
                .inventoryDate(request.getInventoryDate())
                .status(InventoryStatus.DRAFT)
                .keysApartment(0)
                .keysMailbox(0)
                .keysCellar(0)
                .accessCards(0)
                .parkingRemotes(0)
                .build();

        inventory = inventoryRepository.save(inventory);

        List<ApartmentRoom> rooms = apartmentRoomNewRepository.findByApartmentIdWithDetails(
                contract.getApartment().getIdApartment()
        );

        if (!rooms.isEmpty()) {
            List<Long> roomIds = rooms.stream().map(ApartmentRoom::getId).toList();
            apartmentRoomNewRepository.findEquipmentImagesForRooms(roomIds);
        }

        int orderIndex = 0;
        for (ApartmentRoom room : rooms) {
            String sectionName = room.getRoomName() != null ? room.getRoomName() : room.getRoomType().getName();

            InventoryRoomEntry entry = InventoryRoomEntry.builder()
                    .inventory(inventory)
                    .apartmentRoom(room)
                    .sectionName(sectionName)
                    .description("")
                    .orderIndex(orderIndex++)
                    .build();

            entry = roomEntryRepository.save(entry);

            int photoOrder = 0;

            List<RoomImage> roomImages = room.getImages();
            if (roomImages != null && !roomImages.isEmpty()) {
                for (RoomImage roomImage : roomImages) {
                    InventoryRoomPhoto photo = InventoryRoomPhoto.builder()
                            .roomEntry(entry)
                            .photoUrl(roomImage.getImageUrl())
                            .orderIndex(photoOrder++)
                            .build();
                    roomPhotoRepository.save(photo);
                }
            }

            List<RoomEquipment> equipments = room.getEquipments();
            if (equipments != null && !equipments.isEmpty()) {
                for (RoomEquipment equipment : equipments) {
                    List<RoomImage> equipmentImages = equipment.getImages();
                    if (equipmentImages != null && !equipmentImages.isEmpty()) {
                        for (RoomImage equipmentImage : equipmentImages) {
                            InventoryRoomPhoto photo = InventoryRoomPhoto.builder()
                                    .roomEntry(entry)
                                    .photoUrl(equipmentImage.getImageUrl())
                                    .orderIndex(photoOrder++)
                                    .build();
                            roomPhotoRepository.save(photo);
                        }
                    }
                }
            }
        }

        return convertToDto(inventory);
    }

    public InventoryDto getInventoryById(UUID inventoryId) {
        Inventory inventory = inventoryRepository.findById(inventoryId)
                .orElseThrow(() -> new RuntimeException("Inventory not found"));
        return convertToDto(inventory);
    }

    public List<InventoryDto> getInventoriesByContract(UUID contractId) {
        return inventoryRepository.findByContract_Id(contractId)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public InventoryDto updateInventory(UUID inventoryId, InventoryDto dto) {
        Inventory inventory = inventoryRepository.findById(inventoryId)
                .orElseThrow(() -> new RuntimeException("Inventory not found"));

        inventory.setInventoryDate(dto.getInventoryDate());
        inventory.setElectricityMeterNumber(dto.getElectricityMeterNumber());
        inventory.setElectricityDayIndex(dto.getElectricityDayIndex());
        inventory.setElectricityNightIndex(dto.getElectricityNightIndex());
        inventory.setWaterMeterNumber(dto.getWaterMeterNumber());
        inventory.setWaterIndex(dto.getWaterIndex());
        inventory.setHeatingMeterNumber(dto.getHeatingMeterNumber());
        inventory.setHeatingKwhIndex(dto.getHeatingKwhIndex());
        inventory.setHeatingM3Index(dto.getHeatingM3Index());
        inventory.setKeysApartment(dto.getKeysApartment());
        inventory.setKeysMailbox(dto.getKeysMailbox());
        inventory.setKeysCellar(dto.getKeysCellar());
        inventory.setAccessCards(dto.getAccessCards());
        inventory.setParkingRemotes(dto.getParkingRemotes());

        inventory = inventoryRepository.save(inventory);
        return convertToDto(inventory);
    }

    @Transactional
    public InventoryDto signInventoryByOwner(UUID inventoryId, String signatureData) {
        Inventory inventory = inventoryRepository.findById(inventoryId)
                .orElseThrow(() -> new RuntimeException("Inventory not found"));

        inventory.setOwnerSignatureData(signatureData);
        inventory.setOwnerSignedAt(LocalDateTime.now());

        if (inventory.getTenantSignedAt() != null) {
            inventory.setStatus(InventoryStatus.SIGNED);
        } else {
            inventory.setStatus(InventoryStatus.PENDING_SIGNATURE);
        }

        inventory = inventoryRepository.save(inventory);
        return convertToDto(inventory);
    }

    @Transactional
    public InventoryDto signInventoryByTenant(UUID inventoryId, String signatureData) {
        Inventory inventory = inventoryRepository.findById(inventoryId)
                .orElseThrow(() -> new RuntimeException("Inventory not found"));

        inventory.setTenantSignatureData(signatureData);
        inventory.setTenantSignedAt(LocalDateTime.now());

        if (inventory.getOwnerSignedAt() != null) {
            inventory.setStatus(InventoryStatus.SIGNED);
        } else {
            inventory.setStatus(InventoryStatus.PENDING_SIGNATURE);
        }

        inventory = inventoryRepository.save(inventory);
        return convertToDto(inventory);
    }

    private InventoryDto convertToDto(Inventory inventory) {
        List<InventoryRoomEntryDto> roomEntries = roomEntryRepository.findByInventory_IdOrderByOrderIndex(inventory.getId())
                .stream()
                .map(this::convertRoomEntryToDto)
                .collect(Collectors.toList());

        return InventoryDto.builder()
                .id(inventory.getId().toString())
                .contractId(inventory.getContract().getId().toString())
                .type(inventory.getType().name())
                .inventoryDate(inventory.getInventoryDate())
                .electricityMeterNumber(inventory.getElectricityMeterNumber())
                .electricityDayIndex(inventory.getElectricityDayIndex())
                .electricityNightIndex(inventory.getElectricityNightIndex())
                .waterMeterNumber(inventory.getWaterMeterNumber())
                .waterIndex(inventory.getWaterIndex())
                .heatingMeterNumber(inventory.getHeatingMeterNumber())
                .heatingKwhIndex(inventory.getHeatingKwhIndex())
                .heatingM3Index(inventory.getHeatingM3Index())
                .keysApartment(inventory.getKeysApartment())
                .keysMailbox(inventory.getKeysMailbox())
                .keysCellar(inventory.getKeysCellar())
                .accessCards(inventory.getAccessCards())
                .parkingRemotes(inventory.getParkingRemotes())
                .status(inventory.getStatus().name())
                .ownerSignedAt(inventory.getOwnerSignedAt())
                .tenantSignedAt(inventory.getTenantSignedAt())
                .pdfUrl(inventory.getPdfUrl())
                .roomEntries(roomEntries)
                .createdAt(inventory.getCreatedAt())
                .updatedAt(inventory.getUpdatedAt())
                .build();
    }

    private InventoryRoomEntryDto convertRoomEntryToDto(InventoryRoomEntry entry) {
        String sectionName = entry.getSectionName();
        if (sectionName == null && entry.getApartmentRoom() != null) {
            ApartmentRoom room = entry.getApartmentRoom();
            sectionName = room.getRoomName() != null ? room.getRoomName() : room.getRoomType().getName();
        }

        List<InventoryRoomPhotoDto> photos = roomPhotoRepository.findByRoomEntry_IdOrderByOrderIndex(entry.getId())
                .stream()
                .map(this::convertRoomPhotoToDto)
                .collect(Collectors.toList());

        return InventoryRoomEntryDto.builder()
                .id(entry.getId().toString())
                .inventoryId(entry.getInventory().getId().toString())
                .roomId(entry.getApartmentRoom() != null ? entry.getApartmentRoom().getId().toString() : null)
                .sectionName(sectionName)
                .description(entry.getDescription())
                .orderIndex(entry.getOrderIndex())
                .photos(photos)
                .createdAt(entry.getCreatedAt())
                .updatedAt(entry.getUpdatedAt())
                .build();
    }

    private InventoryRoomPhotoDto convertRoomPhotoToDto(InventoryRoomPhoto photo) {
        return InventoryRoomPhotoDto.builder()
                .id(photo.getId().toString())
                .roomEntryId(photo.getRoomEntry().getId().toString())
                .photoUrl(photo.getPhotoUrl())
                .caption(photo.getCaption())
                .orderIndex(photo.getOrderIndex())
                .createdAt(photo.getCreatedAt())
                .build();
    }

    @Transactional
    public void updateRoomEntryDescription(UUID inventoryId, UUID roomEntryId, String description) {
        InventoryRoomEntry entry = roomEntryRepository.findById(roomEntryId)
                .orElseThrow(() -> new RuntimeException("Room entry not found"));

        if (!entry.getInventory().getId().equals(inventoryId)) {
            throw new RuntimeException("Room entry does not belong to this inventory");
        }

        entry.setDescription(description);
        roomEntryRepository.save(entry);
    }

    @Transactional
    public InventoryRoomPhotoDto uploadRoomPhoto(UUID inventoryId, UUID roomEntryId, MultipartFile file) throws IOException {
        InventoryRoomEntry entry = roomEntryRepository.findById(roomEntryId)
                .orElseThrow(() -> new RuntimeException("Room entry not found"));

        if (!entry.getInventory().getId().equals(inventoryId)) {
            throw new RuntimeException("Room entry does not belong to this inventory");
        }

        String photoUrl = fileService.uploadFile(file,"IMAGE",inventoryId.toString()).toString();

        int nextOrder = roomPhotoRepository.findByRoomEntry_IdOrderByOrderIndex(roomEntryId).size();

        InventoryRoomPhoto photo = InventoryRoomPhoto.builder()
                .roomEntry(entry)
                .photoUrl(photoUrl)
                .orderIndex(nextOrder)
                .build();

        photo = roomPhotoRepository.save(photo);
        return convertRoomPhotoToDto(photo);
    }

    public List<InventoryRoomPhotoDto> getRoomPhotos(UUID inventoryId, UUID roomEntryId) {
        InventoryRoomEntry entry = roomEntryRepository.findById(roomEntryId)
                .orElseThrow(() -> new RuntimeException("Room entry not found"));

        if (!entry.getInventory().getId().equals(inventoryId)) {
            throw new RuntimeException("Room entry does not belong to this inventory");
        }

        return roomPhotoRepository.findByRoomEntry_IdOrderByOrderIndex(roomEntryId)
                .stream()
                .map(this::convertRoomPhotoToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteRoomPhoto(UUID inventoryId, UUID roomEntryId, UUID photoId) {
        InventoryRoomPhoto photo = roomPhotoRepository.findById(photoId)
                .orElseThrow(() -> new RuntimeException("Photo not found"));

        if (!photo.getRoomEntry().getId().equals(roomEntryId) ||
            !photo.getRoomEntry().getInventory().getId().equals(inventoryId)) {
            throw new RuntimeException("Photo does not belong to this room entry");
        }

        roomPhotoRepository.delete(photo);
    }
}
