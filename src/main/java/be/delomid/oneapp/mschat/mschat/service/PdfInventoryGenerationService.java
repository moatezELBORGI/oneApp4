package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.DocumentRepository;
import be.delomid.oneapp.mschat.mschat.repository.InventoryRepository;
import be.delomid.oneapp.mschat.mschat.repository.InventoryRoomEntryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType0Font;
import org.apache.pdfbox.pdmodel.font.PDFont;
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
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class PdfInventoryGenerationService {

    private final InventoryRepository inventoryRepository;
    private final InventoryRoomEntryRepository roomEntryRepository;
    private final DocumentService documentService;
    private final DocumentRepository documentRepository;

    @Value("${app.documents.base-dir:documents}")
    private String baseDocumentsDir;

    private static final float MARGIN = 50;
    private static final float FONT_SIZE_TITLE = 16;
    private static final float FONT_SIZE_SUBTITLE = 12;
    private static final float FONT_SIZE_NORMAL = 10;
    private static final float LINE_HEIGHT = 15;
    private static final float SIGNATURE_WIDTH = 150;
    private static final float SIGNATURE_HEIGHT = 75;
    private static final Color BLUE_COLOR = new Color(0, 102, 204); // Bleu professionnel

    // Font holders for the document
    private PDFont fontRegular;
    private PDFont fontBold;

    // Helper class to hold stream and position
    private static class PageContext {
        PDPageContentStream stream;
        float yPosition;

        PageContext(PDPageContentStream stream, float yPosition) {
            this.stream = stream;
            this.yPosition = yPosition;
        }
    }

    public String generateInventoryPdf(UUID inventoryId) throws IOException {
        Inventory inventory = inventoryRepository.findById(inventoryId)
                .orElseThrow(() -> new RuntimeException("Inventory not found"));

        LeaseContract contract = inventory.getContract();
        Apartment apartment = contract.getApartment();
        Building building = apartment.getBuilding();

        Folder apartmentFolder = documentService.getOrCreateApartmentFolder(
                apartment.getIdApartment(),
                building.getBuildingId(),
                contract.getOwner().getIdUsers()
        );

        PDDocument document = new PDDocument();

        try {
            // Load Unicode-supporting fonts
            loadFonts(document);

            addInventoryPages(document, inventory, contract, apartment, building);

            String typeText = inventory.getType() == InventoryType.ENTRY ? "entree" : "sortie";
            String fileName = "etat_des_lieux_" + typeText + "_" + inventoryId + ".pdf";
            String folderPath = Paths.get(baseDocumentsDir, apartmentFolder.getFolderPath()).toString();

            Files.createDirectories(Paths.get(folderPath));

            String filePath = Paths.get(folderPath, fileName).toString();
            document.save(filePath);

            log.info("Generated PDF for inventory {}: {}", inventoryId, filePath);

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
                    .description("État des lieux " + typeText + " - " + apartment.getApartmentLabel())
                    .build();

            documentRepository.save(doc);

            String publicUrl = "http://109.136.4.153:9090/api/v1/documents/" + doc.getId() + "/download";
            inventory.setPdfUrl(publicUrl);
            inventoryRepository.save(inventory);

            return publicUrl;
        } finally {
            document.close();
        }
    }
    // Méthode pour centrer un texte
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
    private void loadFonts(PDDocument document) throws IOException {
        // Try to load TrueType fonts that support Unicode characters (accents, etc.)

        // Option 1: Load from resources (add fonts to src/main/resources/fonts/)
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

        // Option 2: Try system fonts (Linux)
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

        // Option 3: Try DejaVu fonts (more common on Linux)
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

        // Option 4: Windows fonts
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

        // Fallback: Use Helvetica with sanitized text
        log.warn("No Unicode fonts available - using Helvetica with text sanitization");
        fontRegular = null;
        fontBold = null;
    }

    private String sanitizeText(String text) {
        if (text == null) {
            return "";
        }

        // Always remove control characters that cause issues
        text = text.replace("\n", " ")
                .replace("\r", " ")
                .replace("\t", " ")
                .trim();

        // If we have Unicode fonts loaded, return as-is
        if (fontRegular != null) {
            return text;
        }

        // Otherwise, sanitize accents and special characters
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

    private void addInventoryPages(PDDocument document, Inventory inventory,
                                   LeaseContract contract, Apartment apartment, Building building) throws IOException {
        PDPage page = new PDPage(PDRectangle.A4);
        document.addPage(page);

        PDPageContentStream contentStream = new PDPageContentStream(document, page);
        float yPosition = page.getMediaBox().getHeight() - MARGIN;

        try {
            yPosition = addHeader(contentStream, inventory, yPosition);
            yPosition = addParties(contentStream, contract, yPosition);
            yPosition = addPropertyAddress(contentStream, apartment, building, yPosition);
            yPosition = addIntroduction(contentStream, yPosition);

            PageContext ctx = new PageContext(contentStream, yPosition);
            ctx = addMetersSection(ctx, inventory, document);
            ctx = addKeysSection(ctx, inventory, document);
            ctx = addRoomsSection(ctx, inventory, document);
            ctx = addSignatures(ctx, inventory, document);

            ctx.stream.close();
        } catch (IOException e) {
            contentStream.close();
            throw e;
        }
    }

    private float addHeader(PDPageContentStream contentStream, Inventory inventory, float yPosition) throws IOException {
        contentStream.beginText();
        contentStream.setFont(getBoldFont(), FONT_SIZE_TITLE);
        contentStream.newLineAtOffset(MARGIN, yPosition);

        String typeText = inventory.getType() == InventoryType.ENTRY ? "D'ENTRÉE" : "DE SORTIE";
        contentStream.showText(sanitizeText("PROCÈS-VERBAL D'ÉTAT DES LIEUX " + typeText));
        contentStream.endText();

        yPosition -= LINE_HEIGHT * 2;

        contentStream.beginText();
        contentStream.setFont(getRegularFont(), FONT_SIZE_NORMAL);
        contentStream.newLineAtOffset(MARGIN, yPosition);
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
        contentStream.showText(sanitizeText("Le : " + inventory.getInventoryDate().format(formatter)));
        contentStream.endText();

        return yPosition - LINE_HEIGHT * 2;
    }

    private float addParties(PDPageContentStream contentStream, LeaseContract contract, float yPosition) throws IOException {
        contentStream.beginText();
        contentStream.setFont(getRegularFont(), FONT_SIZE_NORMAL);
        contentStream.newLineAtOffset(MARGIN, yPosition);
        contentStream.showText(sanitizeText("Je, soussigné(e) :"));
        contentStream.endText();
        yPosition -= LINE_HEIGHT;

        contentStream.beginText();
        contentStream.setFont(getBoldFont(), FONT_SIZE_NORMAL);
        contentStream.newLineAtOffset(MARGIN, yPosition);
        contentStream.showText(sanitizeText("PROPRIÉTAIRE : " + contract.getOwner().getFname() + " " + contract.getOwner().getLname()));
        contentStream.endText();
        yPosition -= LINE_HEIGHT;

        contentStream.beginText();
        contentStream.setFont(getRegularFont(), FONT_SIZE_NORMAL);
        contentStream.newLineAtOffset(MARGIN, yPosition);
        contentStream.showText("ET");
        contentStream.endText();
        yPosition -= LINE_HEIGHT;

        contentStream.beginText();
        contentStream.setFont(getBoldFont(), FONT_SIZE_NORMAL);
        contentStream.newLineAtOffset(MARGIN, yPosition);
        contentStream.showText(sanitizeText("LOCATAIRE : " + contract.getTenant().getFname() + " " + contract.getTenant().getLname()));
        contentStream.endText();

        return yPosition - LINE_HEIGHT * 2;
    }

    private float addPropertyAddress(PDPageContentStream contentStream, Apartment apartment,
                                     Building building, float yPosition) throws IOException {
        contentStream.beginText();
        contentStream.setFont(getRegularFont(), FONT_SIZE_NORMAL);
        contentStream.newLineAtOffset(MARGIN, yPosition);
        contentStream.showText(sanitizeText("Occupant l'appartement situé à :"));
        contentStream.endText();
        yPosition -= LINE_HEIGHT;

        String address = building.getAddress().getAddress() + " " +
                building.getAddress().getVille() + ", " +
                building.getAddress().getCodePostal();

        contentStream.beginText();
        contentStream.setFont(getBoldFont(), FONT_SIZE_NORMAL);
        contentStream.newLineAtOffset(MARGIN, yPosition);
        contentStream.showText(sanitizeText(address));
        contentStream.endText();

        return yPosition - LINE_HEIGHT * 2;
    }

    private float addIntroduction(PDPageContentStream contentStream, float yPosition) throws IOException {
        String intro = "Déterminer l'état dans lequel le preneur reçoit les lieux loués et celui dans lequel";
        contentStream.beginText();
        contentStream.setFont(getRegularFont(), FONT_SIZE_NORMAL);
        contentStream.newLineAtOffset(MARGIN, yPosition);
        contentStream.showText(sanitizeText(intro));
        contentStream.endText();
        yPosition -= LINE_HEIGHT;

        String intro2 = "il devra les restituer, conformément à la législation en vigueur.";
        contentStream.beginText();
        contentStream.newLineAtOffset(MARGIN, yPosition);
        contentStream.showText(sanitizeText(intro2));
        contentStream.endText();

        return yPosition - LINE_HEIGHT * 2;
    }

    private PageContext addMetersSection(PageContext ctx, Inventory inventory, PDDocument document) throws IOException {
        ctx = checkNewPage(ctx, document, 200);

        float pageWidth = document.getPage(document.getNumberOfPages() - 1).getMediaBox().getWidth();
        ctx.yPosition = addCenteredBlueTitle(ctx.stream, "RELEVÉ DES COMPTEURS", ctx.yPosition, pageWidth);

        // Tableau des compteurs
        float tableStartY = ctx.yPosition;
        float tableWidth = pageWidth - 2 * MARGIN;
        float col1Width = tableWidth * 0.4f;
        float col2Width = tableWidth * 0.3f;
        float col3Width = tableWidth * 0.3f;
        float rowHeight = 20;

        List<String[]> rows = new ArrayList<>();
        rows.add(new String[]{"Type de compteur", "Numéro", "Index"});

        if (inventory.getElectricityMeterNumber() != null) {
            String index = "";
            if (inventory.getElectricityDayIndex() != null && inventory.getElectricityNightIndex() != null) {
                index = "Jour: " + inventory.getElectricityDayIndex() + " kWh, Nuit: " + inventory.getElectricityNightIndex() + " kWh";
            } else if (inventory.getElectricityDayIndex() != null) {
                index = inventory.getElectricityDayIndex() + " kWh";
            }
            rows.add(new String[]{"Électricité", inventory.getElectricityMeterNumber(), index});
        }

        if (inventory.getWaterMeterNumber() != null) {
            String index = inventory.getWaterIndex() != null ? inventory.getWaterIndex().toString() : "";
            rows.add(new String[]{"Eau froide", inventory.getWaterMeterNumber(), index});
        }

        if (inventory.getHeatingMeterNumber() != null) {
            String index = inventory.getHeatingKwhIndex() != null ? inventory.getHeatingKwhIndex() + " kWh" : "";
            rows.add(new String[]{"Calorimètre", inventory.getHeatingMeterNumber(), index});
        }

        // Dessiner le tableau
        for (int i = 0; i < rows.size(); i++) {
            float rowY = tableStartY - i * rowHeight;

            // Bordures
            ctx.stream.setLineWidth(0.5f);
            ctx.stream.addRect(MARGIN, rowY - rowHeight, col1Width, rowHeight);
            ctx.stream.addRect(MARGIN + col1Width, rowY - rowHeight, col2Width, rowHeight);
            ctx.stream.addRect(MARGIN + col1Width + col2Width, rowY - rowHeight, col3Width, rowHeight);
            ctx.stream.stroke();

            // Contenu
            String[] row = rows.get(i);
            PDFont font = (i == 0) ? getBoldFont() : getRegularFont();

            ctx.stream.setFont(font, FONT_SIZE_NORMAL);
            ctx.stream.beginText();
            ctx.stream.newLineAtOffset(MARGIN + 5, rowY - rowHeight + 6);
            ctx.stream.showText(sanitizeText(row[0]));
            ctx.stream.endText();

            ctx.stream.beginText();
            ctx.stream.newLineAtOffset(MARGIN + col1Width + 5, rowY - rowHeight + 6);
            ctx.stream.showText(sanitizeText(row[1]));
            ctx.stream.endText();

            ctx.stream.beginText();
            ctx.stream.newLineAtOffset(MARGIN + col1Width + col2Width + 5, rowY - rowHeight + 6);
            ctx.stream.showText(sanitizeText(row[2]));
            ctx.stream.endText();
        }

        ctx.yPosition = tableStartY - rows.size() * rowHeight - LINE_HEIGHT * 2;
        return ctx;
    }
    private PageContext addKeysSection(PageContext ctx, Inventory inventory, PDDocument document) throws IOException {
        ctx = checkNewPage(ctx, document, 150);

        float pageWidth = document.getPage(document.getNumberOfPages() - 1).getMediaBox().getWidth();
        ctx.yPosition = addCenteredBlueTitle(ctx.stream, "CLÉS REMISES", ctx.yPosition, pageWidth);

        // Tableau des clés
        float tableStartY = ctx.yPosition;
        float tableWidth = pageWidth - 2 * MARGIN;
        float col1Width = tableWidth * 0.7f;
        float col2Width = tableWidth * 0.3f;
        float rowHeight = 20;

        String[][] rows = {
                {"Type", "Quantité"},
                {"Clé(s) appartement", String.valueOf(inventory.getKeysApartment())},
                {"Clé(s) boîte aux lettres", String.valueOf(inventory.getKeysMailbox())},
                {"Clé(s) cave", String.valueOf(inventory.getKeysCellar())},
                {"Carte(s) d'accès", String.valueOf(inventory.getAccessCards())},
                {"Télécommande(s) parking", String.valueOf(inventory.getParkingRemotes())}
        };

        // Dessiner le tableau
        for (int i = 0; i < rows.length; i++) {
            float rowY = tableStartY - i * rowHeight;

            // Bordures
            ctx.stream.setLineWidth(0.5f);
            ctx.stream.addRect(MARGIN, rowY - rowHeight, col1Width, rowHeight);
            ctx.stream.addRect(MARGIN + col1Width, rowY - rowHeight, col2Width, rowHeight);
            ctx.stream.stroke();

            // Contenu
            PDFont font = (i == 0) ? getBoldFont() : getRegularFont();

            ctx.stream.setFont(font, FONT_SIZE_NORMAL);
            ctx.stream.beginText();
            ctx.stream.newLineAtOffset(MARGIN + 5, rowY - rowHeight + 6);
            ctx.stream.showText(sanitizeText(rows[i][0]));
            ctx.stream.endText();

            ctx.stream.beginText();
            ctx.stream.newLineAtOffset(MARGIN + col1Width + 5, rowY - rowHeight + 6);
            ctx.stream.showText(sanitizeText(rows[i][1]));
            ctx.stream.endText();
        }

        ctx.yPosition = tableStartY - rows.length * rowHeight - LINE_HEIGHT * 2;
        return ctx;
    }

    private PageContext addRoomsSection(PageContext ctx, Inventory inventory, PDDocument document) throws IOException {
        List<InventoryRoomEntry> entries = roomEntryRepository.findByInventory_IdOrderByOrderIndex(inventory.getId());

        for (InventoryRoomEntry entry : entries) {
            ctx = checkNewPage(ctx, document, 80);

             float pageWidth =
                    document.getPage(document.getNumberOfPages() - 1)
                            .getMediaBox().getWidth();

            float paragraphWidth = pageWidth - 2 * MARGIN;

            String roomName = entry.getSectionName() != null ? entry.getSectionName() :
                    (entry.getApartmentRoom() != null ? entry.getApartmentRoom().getRoomName() : "Section");

            ctx.yPosition = addCenteredBlueTitle(ctx.stream, roomName.toUpperCase(), ctx.yPosition, pageWidth);

            if (entry.getDescription() != null && !entry.getDescription().isEmpty()) {
                 String[] lines = splitTextToFitWidth(
                        sanitizeText(entry.getDescription()),
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

            }

            ctx.yPosition -= LINE_HEIGHT;
        }

        return ctx;
    }
    private void drawLeftText(PDPageContentStream stream, String text, float x, float y)
            throws IOException {
        stream.beginText();
        stream.newLineAtOffset(x, y);
        stream.showText(text);
        stream.endText();
    }
    private void drawSmartText(
            PDPageContentStream stream,
            String text,
            float x,
            float y,
            float maxWidth,
            PDFont font,
            float fontSize,
            boolean isLastLine
    ) throws IOException {

        String[] words = text.trim().split("\\s+");

        // Cas simples → aligné à gauche
        if (words.length <= 1 || isLastLine) {
            drawLeftText(stream, text, x, y);
            return;
        }

        float textWidth = 0;
        for (String word : words) {
            textWidth += font.getStringWidth(word) / 1000 * fontSize;
        }

        float naturalSpace =
                font.getStringWidth(" ") / 1000 * fontSize;

        float naturalLineWidth =
                textWidth + naturalSpace * (words.length - 1);

        // 👉 Si la ligne est trop courte → PAS DE JUSTIFICATION
        if (naturalLineWidth < maxWidth * 0.85f) {
            drawLeftText(stream, text, x, y);
            return;
        }

        float extraSpace = maxWidth - textWidth;
        float spaceWidth = extraSpace / (words.length - 1);

        stream.beginText();
        stream.newLineAtOffset(x, y);

        for (int i = 0; i < words.length; i++) {
            stream.showText(words[i]);
            if (i < words.length - 1) {
                float wordWidth =
                        font.getStringWidth(words[i]) / 1000 * fontSize;
                stream.newLineAtOffset(wordWidth + spaceWidth, 0);
            }
        }

        stream.endText();
    }

    private void drawJustifiedText(PDPageContentStream stream, String text, float x, float y,
                                   float maxWidth, PDFont font, float fontSize) throws IOException {
        String[] words = text.split("\\s+");
        if (words.length <= 1) {
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

        float totalSpaces = words.length - 1;
        float spaceWidth = (maxWidth - textWidth) / totalSpaces;

        float currentX = x;
        stream.beginText();
        stream.newLineAtOffset(currentX, y);

        for (int i = 0; i < words.length; i++) {
            stream.showText(words[i]);
            if (i < words.length - 1) {
                float wordWidth = font.getStringWidth(words[i]) / 1000 * fontSize;
                currentX += wordWidth + spaceWidth;
                stream.newLineAtOffset(wordWidth + spaceWidth, 0);
            }
        }
        stream.endText();
    }



    private PageContext addSignatures(PageContext ctx, Inventory inventory, PDDocument document) throws IOException {
        ctx = checkNewPage(ctx, document, 200);

        ctx.yPosition -= LINE_HEIGHT * 2;

        float pageWidth = document.getPage(document.getNumberOfPages() - 1).getMediaBox().getWidth();
        ctx.yPosition = addCenteredBlueTitle(ctx.stream, "SIGNATURES", ctx.yPosition, pageWidth);

        float leftSignatureX = MARGIN;
        float rightSignatureX = pageWidth - MARGIN - SIGNATURE_WIDTH;

        ctx.stream.setFont(getRegularFont(), FONT_SIZE_NORMAL);

        ctx.stream.beginText();
        ctx.stream.newLineAtOffset(leftSignatureX, ctx.yPosition);
        ctx.stream.showText(sanitizeText("Propriétaire"));
        ctx.stream.endText();

        ctx.stream.beginText();
        ctx.stream.newLineAtOffset(rightSignatureX, ctx.yPosition);
        ctx.stream.showText(sanitizeText("Locataire"));
        ctx.stream.endText();

        ctx.yPosition -= LINE_HEIGHT * 1.5f;

        if (inventory.getOwnerSignatureData() != null && !inventory.getOwnerSignatureData().isEmpty()) {
            try {
                PDImageXObject ownerSignature = base64ToPDImage(inventory.getOwnerSignatureData(), document);
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

        if (inventory.getTenantSignatureData() != null && !inventory.getTenantSignatureData().isEmpty()) {
            try {
                PDImageXObject tenantSignature = base64ToPDImage(inventory.getTenantSignatureData(), document);
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

            // Check if data starts with "data:image/png;base64,[" (array format)
            if (base64Data.startsWith("data:image/png;base64,[")) {
                // Extract the array part and convert to bytes
                String arrayPart = base64Data.substring(base64Data.indexOf("[") + 1, base64Data.lastIndexOf("]"));
                String[] byteStrings = arrayPart.split(",\\s*");
                imageBytes = new byte[byteStrings.length];

                for (int i = 0; i < byteStrings.length; i++) {
                    imageBytes[i] = (byte) Integer.parseInt(byteStrings[i].trim());
                }

                log.debug("Converted byte array to image bytes, length: {}", imageBytes.length);
            }
            // Standard base64 string
            else {
                String imageData = base64Data;
                if (imageData.contains(",")) {
                    imageData = imageData.substring(imageData.indexOf(",") + 1);
                }
                imageBytes = Base64.getDecoder().decode(imageData);
                log.debug("Decoded base64 string, length: {}", imageBytes.length);
            }

            // Convert to BufferedImage
            ByteArrayInputStream bais = new ByteArrayInputStream(imageBytes);
            BufferedImage bufferedImage = ImageIO.read(bais);

            if (bufferedImage == null) {
                throw new IOException("Failed to read image from data");
            }

            log.debug("BufferedImage dimensions: {}x{}", bufferedImage.getWidth(), bufferedImage.getHeight());

            // Write to temporary file
            File tempFile = File.createTempFile("signature_", ".png");
            tempFile.deleteOnExit();
            ImageIO.write(bufferedImage, "png", tempFile);

            // Load as PDImageXObject
            PDImageXObject image = PDImageXObject.createFromFile(tempFile.getAbsolutePath(), document);
            log.info("PDImageXObject created successfully from signature data");

            return image;
        } catch (Exception e) {
            log.error("Failed to convert signature data to PDImage: {}", e.getMessage(), e);
            throw new IOException("Failed to process signature image: " + e.getMessage(), e);
        }
    }

    private PageContext checkNewPage(PageContext ctx, PDDocument document, float neededSpace) throws IOException {
        if (ctx.yPosition - neededSpace < MARGIN) {
            ctx.stream.close();
            PDPage newPage = new PDPage(PDRectangle.A4);
            document.addPage(newPage);
            PDPageContentStream newStream = new PDPageContentStream(document, newPage);

            // Set default font for the new page
            newStream.setFont(getRegularFont(), FONT_SIZE_NORMAL);

            float newYPosition = newPage.getMediaBox().getHeight() - MARGIN;
            return new PageContext(newStream, newYPosition);
        }
        return ctx;
    }

    private String[] splitTextToFitWidth(
            String text,
            PDFont font,
            float fontSize,
            float maxWidth
    ) throws IOException {

        text = text.replace("\n", " ").replace("\r", " ").trim();
        String[] words = text.split("\\s+");

        List<String> lines = new ArrayList<>();
        StringBuilder currentLine = new StringBuilder();

        for (String word : words) {
            String testLine =
                    currentLine.length() == 0
                            ? word
                            : currentLine + " " + word;

            float textWidth =
                    font.getStringWidth(testLine) / 1000 * fontSize;

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