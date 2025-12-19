package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateLeaseContractRequest {
    private String apartmentId;
    private String ownerId;
    private String tenantId;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal initialRentAmount;
    private BigDecimal depositAmount;
    private BigDecimal chargesAmount;
    private String regionCode;
}
