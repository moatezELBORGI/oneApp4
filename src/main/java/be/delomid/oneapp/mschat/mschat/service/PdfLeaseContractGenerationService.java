package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.model.LeaseContract;
import be.delomid.oneapp.mschat.mschat.model.LeaseContractArticle;
import be.delomid.oneapp.mschat.mschat.repository.LeaseContractArticleRepository;
import be.delomid.oneapp.mschat.mschat.repository.LeaseContractRepository;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.Paragraph;
import com.itextpdf.layout.element.Text;
import com.itextpdf.layout.properties.TextAlignment;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class PdfLeaseContractGenerationService {

    private final LeaseContractRepository leaseContractRepository;
    private final LeaseContractArticleRepository leaseContractArticleRepository;
    private final FileService fileService;

    public String generateLeaseContractPdf(UUID contractId) {
        try {
            LeaseContract contract = leaseContractRepository.findById(contractId)
                    .orElseThrow(() -> new RuntimeException("Contract not found"));

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            PdfWriter writer = new PdfWriter(baos);
            PdfDocument pdf = new PdfDocument(writer);
            Document document = new Document(pdf);

            Paragraph title = new Paragraph("CONTRAT DE BAIL")
                    .setTextAlignment(TextAlignment.CENTER)
                    .setFontSize(20)
                    .setBold();
            document.add(title);

            document.add(new Paragraph(" "));

            document.add(new Paragraph("ENTRE LES SOUSSIGNÉS :").setBold());
            document.add(new Paragraph(String.format(
                    "Le bailleur : %s %s",
                    contract.getOwner().getFname(),
                    contract.getOwner().getLname()
            )));
            document.add(new Paragraph(String.format("Email : %s", contract.getOwner().getEmail())));
            document.add(new Paragraph(String.format("Téléphone : %s", contract.getOwner().getPhoneNumber())));

            document.add(new Paragraph(" "));

            document.add(new Paragraph("ET :").setBold());
            document.add(new Paragraph(String.format(
                    "Le preneur : %s %s",
                    contract.getTenant().getFname(),
                    contract.getTenant().getLname()
            )));
            document.add(new Paragraph(String.format("Email : %s", contract.getTenant().getEmail())));
            document.add(new Paragraph(String.format("Téléphone : %s", contract.getTenant().getPhoneNumber())));

            document.add(new Paragraph(" "));

            document.add(new Paragraph("IL A ÉTÉ CONVENU CE QUI SUIT :").setBold());
            document.add(new Paragraph(" "));

            List<LeaseContractArticle> articles = leaseContractArticleRepository
                    .findByRegionCodeOrderByOrderIndex(contract.getRegionCode());

            for (LeaseContractArticle article : articles) {
                document.add(new Paragraph(
                        new Text(String.format("Article %s - %s", article.getArticleNumber(), article.getArticleTitle()))
                                .setBold()
                ));
                document.add(new Paragraph(article.getArticleContent()));
                document.add(new Paragraph(" "));
            }

            document.add(new Paragraph(" "));
            document.add(new Paragraph("CONDITIONS FINANCIÈRES :").setBold());
            document.add(new Paragraph(String.format("Loyer mensuel : %.2f €", contract.getInitialRentAmount())));
            if (contract.getChargesAmount() != null) {
                document.add(new Paragraph(String.format("Charges mensuelles : %.2f €", contract.getChargesAmount())));
            }
            if (contract.getDepositAmount() != null) {
                document.add(new Paragraph(String.format("Garantie locative : %.2f €", contract.getDepositAmount())));
            }

            document.add(new Paragraph(" "));
            document.add(new Paragraph(String.format(
                    "Date de début : %s",
                    contract.getStartDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
            )));
            if (contract.getEndDate() != null) {
                document.add(new Paragraph(String.format(
                        "Date de fin : %s",
                        contract.getEndDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
                )));
            }

            document.add(new Paragraph(" "));
            document.add(new Paragraph(" "));
            document.add(new Paragraph("SIGNATURES :").setBold());
            document.add(new Paragraph(" "));

            if (contract.getOwnerSignedAt() != null) {
                document.add(new Paragraph(String.format(
                        "Le bailleur (signé le %s)",
                        contract.getOwnerSignedAt().format(DateTimeFormatter.ofPattern("dd/MM/yyyy à HH:mm"))
                )));
            }

            document.add(new Paragraph(" "));

            if (contract.getTenantSignedAt() != null) {
                document.add(new Paragraph(String.format(
                        "Le preneur (signé le %s)",
                        contract.getTenantSignedAt().format(DateTimeFormatter.ofPattern("dd/MM/yyyy à HH:mm"))
                )));
            }

            document.close();

            byte[] pdfBytes = baos.toByteArray();
            String fileName = String.format("contrat_%s_%s.pdf",
                    contract.getApartment().getIdApartment(),
                    contractId.toString().substring(0, 8));

            String pdfUrl = fileService.uploadFile(pdfBytes, fileName, "application/pdf");

            contract.setPdfUrl(pdfUrl);
            leaseContractRepository.save(contract);

            log.info("Generated PDF for contract {} at {}", contractId, pdfUrl);
            return pdfUrl;

        } catch (Exception e) {
            log.error("Error generating PDF for contract {}", contractId, e);
            throw new RuntimeException("Failed to generate PDF: " + e.getMessage());
        }
    }
}
