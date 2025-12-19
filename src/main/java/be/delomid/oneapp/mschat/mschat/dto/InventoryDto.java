package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryDto {
    private String id;
    private String contractId;
    private String type;
    private LocalDate inventoryDate;
    private String electricityMeterNumber;
    private BigDecimal electricityDayIndex;
    private BigDecimal electricityNightIndex;
    private String waterMeterNumber;
    private BigDecimal waterIndex;
    private String heatingMeterNumber;
    private BigDecimal heatingKwhIndex;
    private BigDecimal heatingM3Index;
    private Integer keysApartment;
    private Integer keysMailbox;
    private Integer keysCellar;
    private Integer accessCards;
    private Integer parkingRemotes;
    private String status;
    private LocalDateTime ownerSignedAt;
    private LocalDateTime tenantSignedAt;
    private String ownerSignatureData;
    private String tenantSignatureData;
    private String pdfUrl;
    @Builder.Default
    private List<InventoryRoomEntryDto> roomEntries = new ArrayList<>();
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
