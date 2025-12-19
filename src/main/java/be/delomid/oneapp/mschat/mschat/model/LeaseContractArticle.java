package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "lease_contract_articles")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LeaseContractArticle {

    @Id
    @GeneratedValue
    @Column(name = "id")
    private UUID id;

    @Column(name = "region_code", nullable = false)
    private String regionCode;

    @Column(name = "article_number", nullable = false)
    private String articleNumber;

    @Column(name = "article_title", nullable = false)
    private String articleTitle;

    @Column(name = "article_content", nullable = false, columnDefinition = "TEXT")
    private String articleContent;

    @Column(name = "order_index")
    @Builder.Default
    private Integer orderIndex = 0;

    @Column(name = "is_mandatory")
    @Builder.Default
    private Boolean isMandatory = true;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
