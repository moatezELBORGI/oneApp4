package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.model.LeaseContract;
import be.delomid.oneapp.mschat.mschat.model.LeaseContractArticle;
import be.delomid.oneapp.mschat.mschat.repository.LeaseContractArticleRepository;
import be.delomid.oneapp.mschat.mschat.repository.LeaseContractRepository;
import com.itextpdf.kernel.colors.ColorConstants;
import com.itextpdf.kernel.colors.DeviceRgb;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.Paragraph;
import com.itextpdf.layout.element.Text;
import com.itextpdf.layout.properties.TextAlignment;
import com.itextpdf.layout.borders.SolidBorder;
import com.itextpdf.kernel.geom.PageSize;
import com.itextpdf.layout.element.LineSeparator;
import com.itextpdf.layout.borders.Border;
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
            pdf.setDefaultPageSize(PageSize.A4);
            Document document = new Document(pdf);

            document.setMargins(50, 50, 50, 50);

            Paragraph mainTitle = new Paragraph("CONTRAT DE BAIL DE RESIDENCE PRINCIPALE")
                    .setTextAlignment(TextAlignment.CENTER)
                    .setFontSize(16)
                    .setBold()
                    .setMarginBottom(10);
            document.add(mainTitle);

            Paragraph subtitle = new Paragraph("(Modèle type établi en conformité avec le Code bruxellois du Logement)")
                    .setTextAlignment(TextAlignment.CENTER)
                    .setFontSize(9)
                    .setItalic()
                    .setMarginBottom(20);
            document.add(subtitle);

            document.add(new Paragraph(" ").setMarginBottom(10));

            Paragraph entreTitle = new Paragraph("ENTRE")
                    .setFontSize(14)
                    .setBold()
                    .setMarginBottom(15);
            document.add(entreTitle);

            Paragraph bailleursection = new Paragraph()
                    .add(new Text("A. Le bailleur\n").setBold().setFontSize(12))
                    .setMarginBottom(5);
            document.add(bailleursection);

            document.add(new Paragraph(String.format(
                    "Nom et prénom : %s %s",
                    contract.getOwner().getFname(),
                    contract.getOwner().getLname()
            )).setFontSize(10).setMarginLeft(20));

            document.add(new Paragraph(String.format("Email : %s", contract.getOwner().getEmail()))
                    .setFontSize(10).setMarginLeft(20));

            if (contract.getOwner().getPhoneNumber() != null) {
                document.add(new Paragraph(String.format("Numéro de téléphone : %s", contract.getOwner().getPhoneNumber()))
                        .setFontSize(10).setMarginLeft(20));
            }

            document.add(new Paragraph(" ").setMarginBottom(10));

            Paragraph etSection = new Paragraph("ET")
                    .setFontSize(14)
                    .setBold()
                    .setMarginBottom(15);
            document.add(etSection);

            Paragraph preneurSection = new Paragraph()
                    .add(new Text("B. Le preneur\n").setBold().setFontSize(12))
                    .setMarginBottom(5);
            document.add(preneurSection);

            document.add(new Paragraph(String.format(
                    "Nom et prénom : %s %s",
                    contract.getTenant().getFname(),
                    contract.getTenant().getLname()
            )).setFontSize(10).setMarginLeft(20));

            document.add(new Paragraph(String.format("Email : %s", contract.getTenant().getEmail()))
                    .setFontSize(10).setMarginLeft(20));

            if (contract.getTenant().getPhoneNumber() != null) {
                document.add(new Paragraph(String.format("Numéro de téléphone : %s", contract.getTenant().getPhoneNumber()))
                        .setFontSize(10).setMarginLeft(20));
            }

            document.add(new Paragraph(" ").setMarginBottom(15));

            Paragraph convenuTitle = new Paragraph("IL A ÉTÉ CONVENU CE QUI SUIT :")
                    .setFontSize(13)
                    .setBold()
                    .setMarginBottom(20)
                    .setMarginTop(10);
            document.add(convenuTitle);

            List<LeaseContractArticle> articles = leaseContractArticleRepository
                    .findByRegionCodeOrderByOrderIndex(contract.getRegionCode());

            for (LeaseContractArticle article : articles) {
                Paragraph articleTitle = new Paragraph()
                        .add(new Text(article.getArticleNumber() + ". ").setBold().setFontSize(11))
                        .add(new Text(article.getArticleTitle()).setBold().setFontSize(11))
                        .setMarginTop(12)
                        .setMarginBottom(8);
                document.add(articleTitle);

                Paragraph articleContent = new Paragraph(article.getArticleContent())
                        .setFontSize(10)
                        .setTextAlignment(TextAlignment.JUSTIFIED)
                        .setMarginLeft(15)
                        .setMarginBottom(5);
                document.add(articleContent);
            }

            document.add(new Paragraph(" ").setMarginTop(20));

            Paragraph financialTitle = new Paragraph("CONDITIONS FINANCIÈRES")
                    .setFontSize(12)
                    .setBold()
                    .setMarginTop(15)
                    .setMarginBottom(10);
            document.add(financialTitle);

            document.add(new Paragraph(String.format("Loyer mensuel : %.2f €", contract.getInitialRentAmount()))
                    .setFontSize(10).setMarginLeft(15));

            if (contract.getChargesAmount() != null) {
                document.add(new Paragraph(String.format("Charges mensuelles : %.2f €", contract.getChargesAmount()))
                        .setFontSize(10).setMarginLeft(15));
            }

            if (contract.getDepositAmount() != null) {
                document.add(new Paragraph(String.format("Garantie locative : %.2f €", contract.getDepositAmount()))
                        .setFontSize(10).setMarginLeft(15));
            }

            document.add(new Paragraph(" ").setMarginBottom(10));

            document.add(new Paragraph(String.format(
                    "Date de début du contrat : %s",
                    contract.getStartDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
            )).setFontSize(10).setMarginLeft(15));

            if (contract.getEndDate() != null) {
                document.add(new Paragraph(String.format(
                        "Date de fin du contrat : %s",
                        contract.getEndDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
                )).setFontSize(10).setMarginLeft(15));
            }

            document.add(new Paragraph(" ").setMarginTop(30));

            Paragraph signatureTitle = new Paragraph("SIGNATURES")
                    .setFontSize(12)
                    .setBold()
                    .setMarginBottom(20);
            document.add(signatureTitle);

            document.add(new Paragraph(" ").setMarginBottom(10));

            if (contract.getOwnerSignedAt() != null) {
                document.add(new Paragraph(String.format(
                        "Le(s) bailleur(s)\nSigné le %s",
                        contract.getOwnerSignedAt().format(DateTimeFormatter.ofPattern("dd/MM/yyyy à HH:mm"))
                )).setFontSize(10).setMarginLeft(50));
            } else {
                document.add(new Paragraph("Le(s) bailleur(s)\n\n\n_________________________")
                        .setFontSize(10).setMarginLeft(50));
            }

            document.add(new Paragraph(" ").setMarginBottom(20));

            if (contract.getTenantSignedAt() != null) {
                document.add(new Paragraph(String.format(
                        "Le(s) preneur(s)\nSigné le %s",
                        contract.getTenantSignedAt().format(DateTimeFormatter.ofPattern("dd/MM/yyyy à HH:mm"))
                )).setFontSize(10).setMarginLeft(50));
            } else {
                document.add(new Paragraph("Le(s) preneur(s)\n\n\n_________________________")
                        .setFontSize(10).setMarginLeft(50));
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
