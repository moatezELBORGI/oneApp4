package be.delomid.oneapp.mschat.mschat.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
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
@JsonInclude(JsonInclude.Include.NON_NULL)
public class LeaseContractDto {
    private String id;
    private String apartmentId;
    private ApartmentDto apartment;
    private String ownerId;
    private ResidentDto owner;
    private String tenantId;
    private ResidentDto tenant;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal initialRentAmount;
    private BigDecimal currentRentAmount;
    private BigDecimal depositAmount;
    private BigDecimal chargesAmount;
    private String regionCode;
    private String status;
    private LocalDateTime ownerSignedAt;
    private LocalDateTime tenantSignedAt;
    private String ownerSignatureData;
    private String tenantSignatureData;
    private String pdfUrl;
    @Builder.Default
    private List<LeaseContractCustomSectionDto> customSections = new ArrayList<>();
    @Builder.Default
    private List<RentIndexationDto> indexations = new ArrayList<>();
    private Boolean hasEntryInventory;
    private Boolean hasExitInventory;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
