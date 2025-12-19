package be.delomid.oneapp.mschat.mschat.model;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class FaqVector {
    private Long idQuestion;
    private String question;
    private String answer;
    private double[] embedding;
}