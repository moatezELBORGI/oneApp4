package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LeaseContractArticleDto {
    private String id;
    private String regionCode;
    private String articleNumber;
    private String articleTitle;
    private String articleContent;
    private Integer orderIndex;
    private Boolean isMandatory;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
