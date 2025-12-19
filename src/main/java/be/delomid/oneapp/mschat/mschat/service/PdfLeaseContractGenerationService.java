package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.DocumentRepository;
import be.delomid.oneapp.mschat.mschat.repository.LeaseContractArticleRepository;
import be.delomid.oneapp.mschat.mschat.repository.LeaseContractCustomSectionRepository;
import be.delomid.oneapp.mschat.mschat.repository.LeaseContractRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.PDType0Font;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class PdfLeaseContractGenerationService {

    private final LeaseContractRepository leaseContractRepository;
    private final LeaseContractArticleRepository leaseContractArticleRepository;
    private final LeaseContractCustomSectionRepository customSectionRepository;
    private final DocumentService documentService;
    private final DocumentRepository documentRepository;

    @Value("${app.documents.base-dir:documents}")
    private String baseDocumentsDir;

    private static final float MARGIN = 50;
    private static final float FONT_SIZE_TITLE = 18;
    private static final float FONT_SIZE_SUBTITLE = 13;
    private static final float FONT_SIZE_NORMAL = 10;
    private static final float LINE_HEIGHT = 15;
    private static final float SIGNATURE_WIDTH = 150;
    private static final float SIGNATURE_HEIGHT = 75;
    private static final Color BLUE_COLOR = new Color(0, 102, 204);

    private PDFont fontRegular;
    private PDFont fontBold;

    private static class PageContext {
        PDPageContentStream stream;
        float yPosition;

        PageContext(PDPageContentStream stream, float yPosition) {
            this.stream = stream;
            this.yPosition = yPosition;
        }
    }

    public String generateLeaseContractPdf(UUID contractId) throws IOException {
        LeaseContract contract = leaseContractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Contract not found"));

        Apartment apartment = contract.getApartment();
        Building building = apartment.getBuilding();

        Folder apartmentFolder = documentService.getOrCreateApartmentFolder(
                apartment.getIdApartment(),
                building.getBuildingId(),
                contract.getOwner().getIdUsers()
        );

        PDDocument document = new PDDocument();

        try {
            loadFonts(document);
            addContractPages(document, contract, apartment, building);

            String fileName = "contrat_bail_" + contractId + ".pdf";
            String folderPath = Paths.get(baseDocumentsDir, apartmentFolder.getFolderPath()).toString();

            Files.createDirectories(Paths.get(folderPath));

            String filePath = Paths.get(folderPath, fileName).toString();
            document.save(filePath);

            log.info("Generated PDF for contract {}: {}", contractId, filePath);

            String storedFilename = UUID.randomUUID().toString() + ".pdf";
            Document doc = Document.builder()
                    .originalFilename(fileName)
                    .storedFilename(storedFilename)
                    .filePath(Paths.get(apartmentFolder.getFolderPath(), fileName).toString())
                    .fileSize((long) new File(filePath).length())
                    .mimeType("application/pdf")
                    .fileExtension(".pdf")
                    .folder(apartmentFolder)
                    .apartment(apartment)
                    .building(building)
                    .uploadedBy(contract.getOwner().getIdUsers())
                    .description("Contrat de bail - " + apartment.getApartmentLabel())
                    .build();

            documentRepository.save(doc);

            String publicUrl = "http://109.136.4.153:9090/api/v1/documents/" + doc.getId() + "/download";
            contract.setPdfUrl(publicUrl);
            leaseContractRepository.save(contract);

            return publicUrl;
        } finally {
            document.close();
        }
    }

    private void loadFonts(PDDocument document) throws IOException {
        try (InputStream regularStream = getClass().getResourceAsStream("/fonts/LiberationSans-Regular.ttf");
             InputStream boldStream = getClass().getResourceAsStream("/fonts/LiberationSans-Bold.ttf")) {

            if (regularStream != null && boldStream != null) {
                fontRegular = PDType0Font.load(document, regularStream);
                fontBold = PDType0Font.load(document, boldStream);
                log.info("Loaded Liberation Sans fonts from resources");
                return;
            }
        } catch (Exception e) {
            log.warn("Could not load Liberation Sans from resources: {}", e.getMessage());
        }

        try {
            File regularFont = new File("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf");
            File boldFont = new File("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf");

            if (regularFont.exists() && boldFont.exists()) {
                fontRegular = PDType0Font.load(document, regularFont);
                fontBold = PDType0Font.load(document, boldFont);
                log.info("Loaded Liberation Sans fonts from system");
                return;
            }
        } catch (Exception e) {
            log.warn("Could not load Liberation Sans from system: {}", e.getMessage());
        }

        try {
            File regularFont = new File("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf");
            File boldFont = new File("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf");

            if (regularFont.exists() && boldFont.exists()) {
                fontRegular = PDType0Font.load(document, regularFont);
                fontBold = PDType0Font.load(document, boldFont);
                log.info("Loaded DejaVu Sans fonts from system");
                return;
            }
        } catch (Exception e) {
            log.warn("Could not load DejaVu fonts: {}", e.getMessage());
        }

        try {
            File regularFont = new File("C:/Windows/Fonts/arial.ttf");
            File boldFont = new File("C:/Windows/Fonts/arialbd.ttf");

            if (regularFont.exists() && boldFont.exists()) {
                fontRegular = PDType0Font.load(document, regularFont);
                fontBold = PDType0Font.load(document, boldFont);
                log.info("Loaded Arial fonts from Windows");
                return;
            }
        } catch (Exception e) {
            log.warn("Could not load Arial fonts: {}", e.getMessage());
        }

        log.warn("No Unicode fonts available - using Helvetica with text sanitization");
        fontRegular = null;
        fontBold = null;
    }

    private String sanitizeText(String text) {
        if (text == null) {
            return "";
        }

        text = text.replace("\n", " ")
                .replace("\r", " ")
                .replace("\t", " ")
                .trim();

        if (fontRegular != null) {
            return text;
        }

        return text
                .replace("é", "e").replace("è", "e").replace("ê", "e").replace("ë", "e")
                .replace("à", "a").replace("â", "a").replace("ä", "a")
                .replace("ù", "u").replace("û", "u").replace("ü", "u")
                .replace("î", "i").replace("ï", "i")
                .replace("ô", "o").replace("ö", "o")
                .replace("ç", "c")
                .replace("É", "E").replace("È", "E").replace("Ê", "E").replace("Ë", "E")
                .replace("À", "A").replace("Â", "A").replace("Ä", "A")
                .replace("Ù", "U").replace("Û", "U").replace("Ü", "U")
                .replace("Î", "I").replace("Ï", "I")
                .replace("Ô", "O").replace("Ö", "O")
                .replace("Ç", "C")
                .replace("'", "'").replace("'", "'")
                .replace("\u201C", "\"").replace("\u201D", "\"")
                .replace("–", "-").replace("—", "-")
                .replaceAll("[^\\x00-\\x7F]", "");
    }

    private PDFont getRegularFont() {
        return fontRegular != null ? fontRegular : new PDType1Font(Standard14Fonts.FontName.HELVETICA);
    }

    private PDFont getBoldFont() {
        return fontBold != null ? fontBold : new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
    }

    private float getCenteredX(String text, PDFont font, float fontSize, float pageWidth) throws IOException {
        float textWidth = font.getStringWidth(sanitizeText(text)) / 1000 * fontSize;
        return (pageWidth - textWidth) / 2;
    }

    private float addCenteredBlueTitle(PDPageContentStream stream, String title, float yPosition, float pageWidth) throws IOException {
        stream.setNonStrokingColor(BLUE_COLOR);
        stream.setFont(getBoldFont(), FONT_SIZE_SUBTITLE);

        float centeredX = getCenteredX(title, getBoldFont(), FONT_SIZE_SUBTITLE, pageWidth);

        stream.beginText();
        stream.newLineAtOffset(centeredX, yPosition);
        stream.showText(sanitizeText(title));
        stream.endText();

        stream.setNonStrokingColor(Color.BLACK);

        return yPosition - LINE_HEIGHT * 2;
    }

    private void addContractPages(PDDocument document, LeaseContract contract,
                                  Apartment apartment, Building building) throws IOException {
        PDPage page = new PDPage(PDRectangle.A4);
        document.addPage(page);

        PDPageContentStream contentStream = new PDPageContentStream(document, page);
        float yPosition = page.getMediaBox().getHeight() - MARGIN;

        try {
            yPosition = addHeader(contentStream, yPosition, page.getMediaBox().getWidth());
            yPosition = addParties(contentStream, contract, yPosition);
            yPosition = addPropertyInfo(contentStream, contract, apartment, building, yPosition);

            PageContext ctx = new PageContext(contentStream, yPosition);
            ctx = addStandardArticles(ctx, contract, document);
            ctx = addCustomSections(ctx, contract, document);
            ctx = addFinancialConditions(ctx, contract, document);
            ctx = addSignatures(ctx, contract, document);

            ctx.stream.close();
        } catch (IOException e) {
            contentStream.close();
            throw e;
        }
    }

    private float addHeader(PDPageContentStream stream, float yPosition, float pageWidth) throws IOException {
        stream.setFont(getBoldFont(), FONT_SIZE_TITLE);
        float centeredX = getCenteredX("CONTRAT DE BAIL", getBoldFont(), FONT_SIZE_TITLE, pageWidth);

        stream.beginText();
        stream.newLineAtOffset(centeredX, yPosition);
        stream.showText(sanitizeText("CONTRAT DE BAIL"));
        stream.endText();

        return yPosition - LINE_HEIGHT * 3;
    }

    private float addParties(PDPageContentStream stream, LeaseContract contract, float yPosition) throws IOException {
        stream.setFont(getBoldFont(), FONT_SIZE_NORMAL);
        stream.beginText();
        stream.newLineAtOffset(MARGIN, yPosition);
        stream.showText(sanitizeText("ENTRE LES SOUSSIGNÉS :"));
        stream.endText();
        yPosition -= LINE_HEIGHT * 1.5f;

        stream.setFont(getRegularFont(), FONT_SIZE_NORMAL);
        stream.beginText();
        stream.newLineAtOffset(MARGIN, yPosition);
        stream.showText(sanitizeText("Le bailleur :"));
        stream.endText();
        yPosition -= LINE_HEIGHT;

        stream.setFont(getBoldFont(), FONT_SIZE_NORMAL);
        stream.beginText();
        stream.newLineAtOffset(MARGIN + 20, yPosition);
        stream.showText(sanitizeText(contract.getOwner().getFname() + " " + contract.getOwner().getLname()));
        stream.endText();
        yPosition -= LINE_HEIGHT;

        stream.setFont(getRegularFont(), FONT_SIZE_NORMAL);
        stream.beginText();
        stream.newLineAtOffset(MARGIN + 20, yPosition);
        stream.showText(sanitizeText("Email : " + contract.getOwner().getEmail()));
        stream.endText();
        yPosition -= LINE_HEIGHT;

        if (contract.getOwner().getPhoneNumber() != null) {
            stream.beginText();
            stream.newLineAtOffset(MARGIN + 20, yPosition);
            stream.showText(sanitizeText("Téléphone : " + contract.getOwner().getPhoneNumber()));
            stream.endText();
            yPosition -= LINE_HEIGHT;
        }

        yPosition -= LINE_HEIGHT;

        stream.setFont(getBoldFont(), FONT_SIZE_NORMAL);
        stream.beginText();
        stream.newLineAtOffset(MARGIN, yPosition);
        stream.showText("ET");
        stream.endText();
        yPosition -= LINE_HEIGHT * 1.5f;

        stream.setFont(getRegularFont(), FONT_SIZE_NORMAL);
        stream.beginText();
        stream.newLineAtOffset(MARGIN, yPosition);
        stream.showText(sanitizeText("Le preneur :"));
        stream.endText();
        yPosition -= LINE_HEIGHT;

        stream.setFont(getBoldFont(), FONT_SIZE_NORMAL);
        stream.beginText();
        stream.newLineAtOffset(MARGIN + 20, yPosition);
        stream.showText(sanitizeText(contract.getTenant().getFname() + " " + contract.getTenant().getLname()));
        stream.endText();
        yPosition -= LINE_HEIGHT;

        stream.setFont(getRegularFont(), FONT_SIZE_NORMAL);
        stream.beginText();
        stream.newLineAtOffset(MARGIN + 20, yPosition);
        stream.showText(sanitizeText("Email : " + contract.getTenant().getEmail()));
        stream.endText();
        yPosition -= LINE_HEIGHT;

        if (contract.getTenant().getPhoneNumber() != null) {
            stream.beginText();
            stream.newLineAtOffset(MARGIN + 20, yPosition);
            stream.showText(sanitizeText("Téléphone : " + contract.getTenant().getPhoneNumber()));
            stream.endText();
            yPosition -= LINE_HEIGHT;
        }

        return yPosition - LINE_HEIGHT * 2;
    }

    private float addPropertyInfo(PDPageContentStream stream, LeaseContract contract,
                                  Apartment apartment, Building building, float yPosition) throws IOException {
        stream.setFont(getRegularFont(), FONT_SIZE_NORMAL);
        stream.beginText();
        stream.newLineAtOffset(MARGIN, yPosition);
        stream.showText(sanitizeText("Concernant le bien situé à l'adresse suivante :"));
        stream.endText();
        yPosition -= LINE_HEIGHT;

        String address = building.getAddress().getAddress() + ", " +
                building.getAddress().getCodePostal() + " " +
                building.getAddress().getVille();

        stream.setFont(getBoldFont(), FONT_SIZE_NORMAL);
        stream.beginText();
        stream.newLineAtOffset(MARGIN + 20, yPosition);
        stream.showText(sanitizeText(address));
        stream.endText();
        yPosition -= LINE_HEIGHT;

        stream.setFont(getRegularFont(), FONT_SIZE_NORMAL);
        stream.beginText();
        stream.newLineAtOffset(MARGIN + 20, yPosition);
        stream.showText(sanitizeText("Appartement : " + apartment.getApartmentLabel()));
        stream.endText();

        return yPosition - LINE_HEIGHT * 2;
    }

    private PageContext addStandardArticles(PageContext ctx, LeaseContract contract, PDDocument document) throws IOException {
        ctx = checkNewPage(ctx, document, 100);

        float pageWidth = document.getPage(document.getNumberOfPages() - 1).getMediaBox().getWidth();
        ctx.yPosition = addCenteredBlueTitle(ctx.stream, "CLAUSES DU CONTRAT", ctx.yPosition, pageWidth);

        List<LeaseContractArticle> articles = leaseContractArticleRepository
                .findByRegionCodeOrderByOrderIndex(contract.getRegionCode());

        for (LeaseContractArticle article : articles) {
            ctx = checkNewPage(ctx, document, 80);

            ctx.stream.setFont(getBoldFont(), FONT_SIZE_NORMAL);
            ctx.stream.beginText();
            ctx.stream.newLineAtOffset(MARGIN, ctx.yPosition);
            ctx.stream.showText(sanitizeText("Article " + article.getArticleNumber() + " - " + article.getArticleTitle()));
            ctx.stream.endText();
            ctx.yPosition -= LINE_HEIGHT * 1.5f;

            float paragraphWidth = pageWidth - 2 * MARGIN;
            String[] lines = splitTextToFitWidth(
                    sanitizeText(article.getArticleContent()),
                    getRegularFont(),
                    FONT_SIZE_NORMAL,
                    paragraphWidth
            );

            ctx.stream.setFont(getRegularFont(), FONT_SIZE_NORMAL);

            for (int i = 0; i < lines.length; i++) {
                ctx = checkNewPage(ctx, document, 20);

                boolean isLastLine = (i == lines.length - 1);

                drawSmartText(
                        ctx.stream,
                        sanitizeText(lines[i]),
                        MARGIN,
                        ctx.yPosition,
                        pageWidth - 2 * MARGIN,
                        getRegularFont(),
                        FONT_SIZE_NORMAL,
                        isLastLine
                );

                ctx.yPosition -= LINE_HEIGHT;
            }

            ctx.yPosition -= LINE_HEIGHT;
        }

        return ctx;
    }

    private PageContext addCustomSections(PageContext ctx, LeaseContract contract, PDDocument document) throws IOException {
        List<LeaseContractCustomSection> customSections = customSectionRepository
                .findByContract_IdOrderByOrderIndex(contract.getId());

        if (!customSections.isEmpty()) {
            ctx = checkNewPage(ctx, document, 100);

            float pageWidth = document.getPage(document.getNumberOfPages() - 1).getMediaBox().getWidth();
            ctx.yPosition = addCenteredBlueTitle(ctx.stream, "CLAUSES PARTICULIÈRES", ctx.yPosition, pageWidth);

            for (LeaseContractCustomSection section : customSections) {
                ctx = checkNewPage(ctx, document, 60);

                ctx.stream.setFont(getBoldFont(), FONT_SIZE_NORMAL);
                ctx.stream.beginText();
                ctx.stream.newLineAtOffset(MARGIN, ctx.yPosition);
                ctx.stream.showText(sanitizeText(section.getSectionTitle()));
                ctx.stream.endText();
                ctx.yPosition -= LINE_HEIGHT * 1.5f;

                float paragraphWidth = pageWidth - 2 * MARGIN;
                String[] lines = splitTextToFitWidth(
                        sanitizeText(section.getSectionContent()),
                        getRegularFont(),
                        FONT_SIZE_NORMAL,
                        paragraphWidth
                );

                ctx.stream.setFont(getRegularFont(), FONT_SIZE_NORMAL);

                for (int i = 0; i < lines.length; i++) {
                    ctx = checkNewPage(ctx, document, 20);

                    boolean isLastLine = (i == lines.length - 1);

                    drawSmartText(
                            ctx.stream,
                            sanitizeText(lines[i]),
                            MARGIN,
                            ctx.yPosition,
                            pageWidth - 2 * MARGIN,
                            getRegularFont(),
                            FONT_SIZE_NORMAL,
                            isLastLine
                    );

                    ctx.yPosition -= LINE_HEIGHT;
                }

                ctx.yPosition -= LINE_HEIGHT;
            }
        }

        return ctx;
    }

    private PageContext addFinancialConditions(PageContext ctx, LeaseContract contract, PDDocument document) throws IOException {
        ctx = checkNewPage(ctx, document, 150);

        float pageWidth = document.getPage(document.getNumberOfPages() - 1).getMediaBox().getWidth();
        ctx.yPosition = addCenteredBlueTitle(ctx.stream, "CONDITIONS FINANCIÈRES", ctx.yPosition, pageWidth);

        ctx.stream.setFont(getRegularFont(), FONT_SIZE_NORMAL);

        ctx.stream.beginText();
        ctx.stream.newLineAtOffset(MARGIN, ctx.yPosition);
        ctx.stream.showText(sanitizeText(String.format("Loyer mensuel : %.2f EUR", contract.getInitialRentAmount())));
        ctx.stream.endText();
        ctx.yPosition -= LINE_HEIGHT;

        if (contract.getChargesAmount() != null) {
            ctx.stream.beginText();
            ctx.stream.newLineAtOffset(MARGIN, ctx.yPosition);
            ctx.stream.showText(sanitizeText(String.format("Charges mensuelles : %.2f EUR", contract.getChargesAmount())));
            ctx.stream.endText();
            ctx.yPosition -= LINE_HEIGHT;
        }

        if (contract.getDepositAmount() != null) {
            ctx.stream.beginText();
            ctx.stream.newLineAtOffset(MARGIN, ctx.yPosition);
            ctx.stream.showText(sanitizeText(String.format("Garantie locative : %.2f EUR", contract.getDepositAmount())));
            ctx.stream.endText();
            ctx.yPosition -= LINE_HEIGHT;
        }

        ctx.yPosition -= LINE_HEIGHT;

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");

        ctx.stream.beginText();
        ctx.stream.newLineAtOffset(MARGIN, ctx.yPosition);
        ctx.stream.showText(sanitizeText("Date de début : " + contract.getStartDate().format(formatter)));
        ctx.stream.endText();
        ctx.yPosition -= LINE_HEIGHT;

        if (contract.getEndDate() != null) {
            ctx.stream.beginText();
            ctx.stream.newLineAtOffset(MARGIN, ctx.yPosition);
            ctx.stream.showText(sanitizeText("Date de fin : " + contract.getEndDate().format(formatter)));
            ctx.stream.endText();
            ctx.yPosition -= LINE_HEIGHT;
        }

        return ctx;
    }

    private PageContext addSignatures(PageContext ctx, LeaseContract contract, PDDocument document) throws IOException {
        ctx = checkNewPage(ctx, document, 250);

        ctx.yPosition -= LINE_HEIGHT * 2;

        float pageWidth = document.getPage(document.getNumberOfPages() - 1).getMediaBox().getWidth();
        ctx.yPosition = addCenteredBlueTitle(ctx.stream, "SIGNATURES", ctx.yPosition, pageWidth);

        float leftSignatureX = MARGIN;
        float rightSignatureX = pageWidth - MARGIN - SIGNATURE_WIDTH;

        ctx.stream.setFont(getRegularFont(), FONT_SIZE_NORMAL);

        ctx.stream.beginText();
        ctx.stream.newLineAtOffset(leftSignatureX, ctx.yPosition);
        ctx.stream.showText(sanitizeText("Le bailleur"));
        ctx.stream.endText();

        ctx.stream.beginText();
        ctx.stream.newLineAtOffset(rightSignatureX, ctx.yPosition);
        ctx.stream.showText(sanitizeText("Le preneur"));
        ctx.stream.endText();

        ctx.yPosition -= LINE_HEIGHT;

        if (contract.getOwnerSignedAt() != null) {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy à HH:mm");
            ctx.stream.setFont(getRegularFont(), 8);
            ctx.stream.beginText();
            ctx.stream.newLineAtOffset(leftSignatureX, ctx.yPosition);
            ctx.stream.showText(sanitizeText("Signé le " + contract.getOwnerSignedAt().format(formatter)));
            ctx.stream.endText();
        }

        if (contract.getTenantSignedAt() != null) {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy à HH:mm");
            ctx.stream.setFont(getRegularFont(), 8);
            ctx.stream.beginText();
            ctx.stream.newLineAtOffset(rightSignatureX, ctx.yPosition);
            ctx.stream.showText(sanitizeText("Signé le " + contract.getTenantSignedAt().format(formatter)));
            ctx.stream.endText();
        }

        ctx.yPosition -= LINE_HEIGHT * 1.5f;

        if (contract.getOwnerSignatureData() != null && !contract.getOwnerSignatureData().isEmpty()) {
            try {
                PDImageXObject ownerSignature = base64ToPDImage(contract.getOwnerSignatureData(), document);
                ctx.stream.drawImage(ownerSignature, leftSignatureX, ctx.yPosition - SIGNATURE_HEIGHT,
                        SIGNATURE_WIDTH, SIGNATURE_HEIGHT);
            } catch (Exception e) {
                log.error("Error adding owner signature: {}", e.getMessage(), e);
                ctx.stream.addRect(leftSignatureX, ctx.yPosition - SIGNATURE_HEIGHT,
                        SIGNATURE_WIDTH, SIGNATURE_HEIGHT);
                ctx.stream.stroke();
            }
        } else {
            ctx.stream.addRect(leftSignatureX, ctx.yPosition - SIGNATURE_HEIGHT,
                    SIGNATURE_WIDTH, SIGNATURE_HEIGHT);
            ctx.stream.stroke();
        }

        if (contract.getTenantSignatureData() != null && !contract.getTenantSignatureData().isEmpty()) {
            try {
                PDImageXObject tenantSignature = base64ToPDImage(contract.getTenantSignatureData(), document);
                ctx.stream.drawImage(tenantSignature, rightSignatureX, ctx.yPosition - SIGNATURE_HEIGHT,
                        SIGNATURE_WIDTH, SIGNATURE_HEIGHT);
            } catch (Exception e) {
                log.error("Error adding tenant signature: {}", e.getMessage(), e);
                ctx.stream.addRect(rightSignatureX, ctx.yPosition - SIGNATURE_HEIGHT,
                        SIGNATURE_WIDTH, SIGNATURE_HEIGHT);
                ctx.stream.stroke();
            }
        } else {
            ctx.stream.addRect(rightSignatureX, ctx.yPosition - SIGNATURE_HEIGHT,
                    SIGNATURE_WIDTH, SIGNATURE_HEIGHT);
            ctx.stream.stroke();
        }

        ctx.yPosition -= SIGNATURE_HEIGHT + LINE_HEIGHT;

        return ctx;
    }

    private PDImageXObject base64ToPDImage(String base64Data, PDDocument document) throws IOException {
        try {
            byte[] imageBytes;

            if (base64Data.startsWith("data:image/png;base64,[")) {
                String arrayPart = base64Data.substring(base64Data.indexOf("[") + 1, base64Data.lastIndexOf("]"));
                String[] byteStrings = arrayPart.split(",\\s*");
                imageBytes = new byte[byteStrings.length];

                for (int i = 0; i < byteStrings.length; i++) {
                    imageBytes[i] = (byte) Integer.parseInt(byteStrings[i].trim());
                }

                log.debug("Converted byte array to image bytes, length: {}", imageBytes.length);
            } else {
                String imageData = base64Data;
                if (imageData.contains(",")) {
                    imageData = imageData.substring(imageData.indexOf(",") + 1);
                }
                imageBytes = Base64.getDecoder().decode(imageData);
                log.debug("Decoded base64 string, length: {}", imageBytes.length);
            }

            ByteArrayInputStream bais = new ByteArrayInputStream(imageBytes);
            BufferedImage bufferedImage = ImageIO.read(bais);

            if (bufferedImage == null) {
                throw new IOException("Failed to read image from data");
            }

            log.debug("BufferedImage dimensions: {}x{}", bufferedImage.getWidth(), bufferedImage.getHeight());

            File tempFile = File.createTempFile("signature_", ".png");
            tempFile.deleteOnExit();
            ImageIO.write(bufferedImage, "png", tempFile);

            PDImageXObject image = PDImageXObject.createFromFile(tempFile.getAbsolutePath(), document);
            log.info("PDImageXObject created successfully from signature data");

            return image;
        } catch (Exception e) {
            log.error("Failed to convert signature data to PDImage: {}", e.getMessage(), e);
            throw new IOException("Failed to process signature image: " + e.getMessage(), e);
        }
    }

    private void drawSmartText(PDPageContentStream stream, String text, float x, float y, float maxWidth,
                               PDFont font, float fontSize, boolean isLastLine) throws IOException {
        String[] words = text.trim().split("\\s+");

        if (words.length <= 1 || isLastLine) {
            stream.beginText();
            stream.newLineAtOffset(x, y);
            stream.showText(text);
            stream.endText();
            return;
        }

        float textWidth = 0;
        for (String word : words) {
            textWidth += font.getStringWidth(word) / 1000 * fontSize;
        }

        float naturalSpace = font.getStringWidth(" ") / 1000 * fontSize;
        float naturalLineWidth = textWidth + naturalSpace * (words.length - 1);

        if (naturalLineWidth < maxWidth * 0.85f) {
            stream.beginText();
            stream.newLineAtOffset(x, y);
            stream.showText(text);
            stream.endText();
            return;
        }

        float extraSpace = maxWidth - textWidth;
        float spaceWidth = extraSpace / (words.length - 1);

        stream.beginText();
        stream.newLineAtOffset(x, y);

        for (int i = 0; i < words.length; i++) {
            stream.showText(words[i]);
            if (i < words.length - 1) {
                float wordWidth = font.getStringWidth(words[i]) / 1000 * fontSize;
                stream.newLineAtOffset(wordWidth + spaceWidth, 0);
            }
        }

        stream.endText();
    }

    private PageContext checkNewPage(PageContext ctx, PDDocument document, float neededSpace) throws IOException {
        if (ctx.yPosition - neededSpace < MARGIN) {
            ctx.stream.close();
            PDPage newPage = new PDPage(PDRectangle.A4);
            document.addPage(newPage);
            PDPageContentStream newStream = new PDPageContentStream(document, newPage);

            newStream.setFont(getRegularFont(), FONT_SIZE_NORMAL);

            float newYPosition = newPage.getMediaBox().getHeight() - MARGIN;
            return new PageContext(newStream, newYPosition);
        }
        return ctx;
    }

    private String[] splitTextToFitWidth(String text, PDFont font, float fontSize, float maxWidth) throws IOException {
        text = text.replace("\n", " ").replace("\r", " ").trim();
        String[] words = text.split("\\s+");

        List<String> lines = new ArrayList<>();
        StringBuilder currentLine = new StringBuilder();

        for (String word : words) {
            String testLine = currentLine.length() == 0 ? word : currentLine + " " + word;

            float textWidth = font.getStringWidth(testLine) / 1000 * fontSize;

            if (textWidth > maxWidth) {
                lines.add(currentLine.toString());
                currentLine = new StringBuilder(word);
            } else {
                if (currentLine.length() > 0) {
                    currentLine.append(" ");
                }
                currentLine.append(word);
            }
        }

        if (currentLine.length() > 0) {
            lines.add(currentLine.toString());
        }

        return lines.toArray(new String[0]);
    }
}
