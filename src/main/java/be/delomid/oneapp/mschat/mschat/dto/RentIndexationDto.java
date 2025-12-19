package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RentIndexationDto {
    private String id;
    private String contractId;
    private LocalDate indexationDate;
    private BigDecimal previousAmount;
    private BigDecimal newAmount;
    private BigDecimal indexationRate;
    private BigDecimal baseIndex;
    private BigDecimal newIndex;
    private String notes;
    private LocalDateTime createdAt;
}
