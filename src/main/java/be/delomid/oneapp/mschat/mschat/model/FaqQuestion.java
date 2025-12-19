package be.delomid.oneapp.mschat.mschat.model;


import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "faq_questions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FaqQuestion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String question;

    @Column(length = 2000)
    private String answer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "topic_id")
    @JsonIgnore   // ⬅️ empêchera la boucle JSON
    private FaqTopic topic;
}
