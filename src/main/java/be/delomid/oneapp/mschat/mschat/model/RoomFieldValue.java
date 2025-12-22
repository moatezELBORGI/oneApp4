package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "room_field_values")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RoomFieldValue {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "apartment_room_id", nullable = false)
    private ApartmentRoom apartmentRoom;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "field_definition_id", nullable = false)
    private RoomTypeFieldDefinition fieldDefinition;

    @Column(name = "text_value", columnDefinition = "TEXT")
    private String textValue;

    @Column(name = "number_value", precision = 10, scale = 2)
    private BigDecimal numberValue;

    @Column(name = "boolean_value")
    private Boolean booleanValue;

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
