package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "apartment_custom_fields")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentCustomField {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "apartment_id", nullable = false)
    private String apartmentId;

    @Column(name = "field_label", nullable = false, length = 255)
    private String fieldLabel;

    @Column(name = "field_value", columnDefinition = "TEXT")
    private String fieldValue;

    @Column(name = "display_order")
    private Integer displayOrder = 0;

    @Column(name = "is_system_field")
    private Boolean isSystemField = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
