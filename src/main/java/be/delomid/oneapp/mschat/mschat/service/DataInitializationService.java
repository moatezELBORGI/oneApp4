package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.config.AppConfig;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class DataInitializationService implements CommandLineRunner {

    private final CountryRepository countryRepository;
    private final ResidentRepository residentRepository;
    private final BuildingRepository buildingRepository;
    private final ApartmentRepository apartmentRepository;
    private final ResidentBuildingRepository residentBuildingRepository;
    private final PasswordEncoder passwordEncoder;
    private final AppConfig appConfig;
    private final FaqTopicRepository faqTopicRepository;
    private final LeaseContractRepository leaseContractRepository;
    private final ApartmentRoomLegacyRepository apartmentRoomLegacyRepository;
    private final LeaseContractArticleRepository leaseContractArticleRepository;
    private final RoomTypeRepository roomTypeRepository;
    private final RoomTypeFieldDefinitionRepository roomTypeFieldDefinitionRepository;
    @Override
    @Transactional
    public void run(String... args) {
        log.info("Initializing application data...");

//     initializeCountries();
//       initializeSuperAdmin();
//      initializeTestData();
//        initFaqData();
//        initializeRoomTypes();

        log.info("Application data initialization completed");
    }

    private void initializeCountries() {
        if (countryRepository.count() == 0) {
            log.info("Initializing countries data...");

            List<Country> countries = Arrays.asList(
                    new Country(null, "France", "FR", "FRA", null),
                    new Country(null, "Belgique", "BE", "BEL", null),
                    new Country(null, "Suisse", "CH", "CHE", null),
                    new Country(null, "Canada", "CA", "CAN", null),
                    new Country(null, "Maroc", "MA", "MAR", null),
                    new Country(null, "Tunisie", "TN", "TUN", null),
                    new Country(null, "Algérie", "DZ", "DZA", null)
            );

            countryRepository.saveAll(countries);
            log.info("Countries initialized: {} countries added", countries.size());
        }
    }

    private void initializeSuperAdmin() {
        String adminEmail = appConfig.getAdmin().getDefaultSuperAdminEmail();
        String adminPassword = appConfig.getAdmin().getDefaultSuperAdminPassword();

        if (adminEmail != null && adminPassword != null &&
                residentRepository.findByEmail(adminEmail).isEmpty()) {

            log.info("Creating default super admin...");

            Resident superAdmin = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Super")
                    .lname("Admin")
                    .email(adminEmail)
                    .password(passwordEncoder.encode(adminPassword))
                    .role(UserRole.SUPER_ADMIN)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            residentRepository.save(superAdmin);
            log.info("Super admin created with email: {}", adminEmail);
        }
    }

    private void initializeTestData() {
        log.info("Cleaning existing data...");

        residentBuildingRepository.deleteAll();
        apartmentRepository.deleteAll();
        buildingRepository.deleteAll();
        residentRepository.deleteAll();

        log.info("Creating Delomid IT Immeuble and users...");

        Country belgium = countryRepository.findByCodeIso3("BEL");
        if (belgium == null) {
            belgium = countryRepository.findAll().get(0);
        }

        // ==================== IMMEUBLE: DELOMID IT IMMEUBLE ====================

        Address addressBruxelles = Address.builder()
                .address("Avenue Louise 250")
                .codePostal("1050")
                .ville("Bruxelles")
                .pays(belgium)
                .build();

        Building building = Building.builder()
                .buildingId("BEL-2025-IT-IMMEUBLE")
                .buildingLabel("Delomid IT Immeuble")
                .buildingNumber("250")
                .yearOfConstruction(2024)
                .numberOfFloors(5)
                .address(addressBruxelles)
                .build();

        building = buildingRepository.save(building);
        log.info("Building created: Delomid IT Immeuble");

        // ==================== ADMIN BUILDING 1 ====================
        Resident adminAmir = Resident.builder()
                .idUsers(UUID.randomUUID().toString())
                .fname("Amir")
                .lname("Admin")
                .email("amir@delomid-it.com")
                .password(passwordEncoder.encode("Delomid2019!"))
                .phoneNumber("+32470111222")
                .role(UserRole.BUILDING_ADMIN)
                .accountStatus(AccountStatus.ACTIVE)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        adminAmir = residentRepository.save(adminAmir);
        log.info("Admin Building 1 created: amir@delomid-it.com / Delomid2019!");

        ResidentBuilding rbAdminAmir = ResidentBuilding.builder()
                .resident(adminAmir)
                .building(building)
                .apartment(null)
                .roleInBuilding(UserRole.BUILDING_ADMIN)
                .build();
        residentBuildingRepository.save(rbAdminAmir);

        // ==================== ADMIN BUILDING 2 ====================
        Resident adminMoatez = Resident.builder()
                .idUsers(UUID.randomUUID().toString())
                .fname("Moatez")
                .lname("Admin")
                .email("moatez@delomid-it.com")
                .password(passwordEncoder.encode("Delomid2019!"))
                .phoneNumber("+32470222333")
                .role(UserRole.BUILDING_ADMIN)
                .accountStatus(AccountStatus.ACTIVE)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        adminMoatez = residentRepository.save(adminMoatez);
        log.info("Admin Building 2 created: moatez@delomid-it.com / Delomid2019!");

        ResidentBuilding rbAdminMoatez = ResidentBuilding.builder()
                .resident(adminMoatez)
                .building(building)
                .apartment(null)
                .roleInBuilding(UserRole.BUILDING_ADMIN)
                .build();
        residentBuildingRepository.save(rbAdminMoatez);

        // ==================== UTILISATEUR 1 (SANS APPARTEMENT) ====================
        Resident user1 = Resident.builder()
                .idUsers(UUID.randomUUID().toString())
                .fname("Moatez")
                .lname("El Borgi")
                .email("moatezelborgi@gmail.com")
                .password(passwordEncoder.encode("Delomid2019!"))
                .phoneNumber("+32470333444")
                .role(UserRole.RESIDENT)
                .accountStatus(AccountStatus.ACTIVE)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        user1 = residentRepository.save(user1);
        log.info("User 1 created: moatezelborgi@gmail.com / Delomid2019!");

        ResidentBuilding rbUser1 = ResidentBuilding.builder()
                .resident(user1)
                .building(building)
                .apartment(null)
                .roleInBuilding(UserRole.RESIDENT)
                .build();
        residentBuildingRepository.save(rbUser1);

        // ==================== UTILISATEUR 2 (SANS APPARTEMENT) ====================
        Resident user2 = Resident.builder()
                .idUsers(UUID.randomUUID().toString())
                .fname("Moatez")
                .lname("Borgi")
                .email("moatezborgi@soft-verse.com")
                .password(passwordEncoder.encode("Delomid2019!"))
                .phoneNumber("+32470444555")
                .role(UserRole.RESIDENT)
                .accountStatus(AccountStatus.ACTIVE)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
        user2 = residentRepository.save(user2);
        log.info("User 2 created: moatezborgi@soft-verse.com / Delomid2019!");

        ResidentBuilding rbUser2 = ResidentBuilding.builder()
                .resident(user2)
                .building(building)
                .apartment(null)
                .roleInBuilding(UserRole.RESIDENT)
                .build();
        residentBuildingRepository.save(rbUser2);

        log.info("==================== INITIALIZATION COMPLETE ====================");
        log.info("Immeuble: Delomid IT Immeuble (Bruxelles, Belgique)");
        log.info("Admin Building 1: amir@delomid-it.com / Delomid2019!");
        log.info("Admin Building 2: moatez@delomid-it.com / Delomid2019!");
        log.info("User 1 (sans appartement): moatezelborgi@gmail.com / Delomid2019!");
        log.info("User 2 (sans appartement): moatezborgi@soft-verse.com / Delomid2019!");
    }
    private void initFaqData()
    {
        String buildingId = "BEL-2025-IT-IMMEUBLE";

        buildingRepository.findById(buildingId).ifPresent(building -> {

            // si ce building a déjà des FAQ, on ne refait rien
            if (!faqTopicRepository.findFaqTopicByBuilding(building).isEmpty()) {
                return;
            }
            // =======================
            //  Building Rules
            // =======================
            FaqTopic buildingRules = new FaqTopic();
            buildingRules.setName("Building Rules");
            buildingRules.setIcon("apartment_rounded");
            buildingRules.setBuilding(building);
            buildingRules.setQuestions(new ArrayList<>());

            FaqQuestion brQ1 = new FaqQuestion();
            brQ1.setQuestion("Puis-je avoir des animaux de compagnie ?");
            brQ1.setAnswer("Oui, sous conditions.");
            brQ1.setTopic(buildingRules);
            buildingRules.getQuestions().add(brQ1);

            FaqQuestion brQ2 = new FaqQuestion();
            brQ2.setQuestion("Y a-t-il des horaires de silence ?");
            brQ2.setAnswer("Oui, généralement entre 22h et 7h.");
            brQ2.setTopic(buildingRules);
            buildingRules.getQuestions().add(brQ2);

            faqTopicRepository.save(buildingRules);

            // =======================
            //  Rent & Payment
            // =======================
            FaqTopic rentPayment = new FaqTopic();
            rentPayment.setName("Rent & Payment");
            rentPayment.setIcon("payments_rounded");
            rentPayment.setBuilding(building);
            rentPayment.setQuestions(new ArrayList<>());

            FaqQuestion rpQ1 = new FaqQuestion();
            rpQ1.setQuestion("Moyens de paiement ?");
            rpQ1.setAnswer("Virement, carte, prélèvement.");
            rpQ1.setTopic(rentPayment);
            rentPayment.getQuestions().add(rpQ1);

            faqTopicRepository.save(rentPayment);

            // =======================
            //  Maintenance
            // =======================
            FaqTopic maintenance = new FaqTopic();
            maintenance.setName("Maintenance");
            maintenance.setIcon("build_rounded");
            maintenance.setBuilding(building);
            maintenance.setQuestions(new ArrayList<>());

            FaqQuestion mQ1 = new FaqQuestion();
            mQ1.setQuestion("Déclarer un problème ?");
            mQ1.setAnswer("Depuis l’app, section Maintenance.");
            mQ1.setTopic(maintenance);
            maintenance.getQuestions().add(mQ1);

            faqTopicRepository.save(maintenance);

            // =======================
            //  Documents
            // =======================
            FaqTopic documents = new FaqTopic();
            documents.setName("Documents");
            documents.setIcon("description_rounded");
            documents.setBuilding(building);
            documents.setQuestions(new ArrayList<>());

            FaqQuestion dQ1 = new FaqQuestion();
            dQ1.setQuestion("Où trouver mon contrat ?");
            dQ1.setAnswer("Dans Mes Documents.");
            dQ1.setTopic(documents);
            documents.getQuestions().add(dQ1);

            faqTopicRepository.save(documents);

            // =======================
            //  Community
            // =======================
            FaqTopic community = new FaqTopic();
            community.setName("Community");
            community.setIcon("groups_rounded");
            community.setBuilding(building);
            community.setQuestions(new ArrayList<>());

            FaqQuestion cQ1 = new FaqQuestion();
            cQ1.setQuestion("Comment sont prises les décisions ?");
            cQ1.setAnswer("Vote / AG.");
            cQ1.setTopic(community);
            community.getQuestions().add(cQ1);

            faqTopicRepository.save(community);

            // =======================
            //  General
            // =======================
            FaqTopic general = new FaqTopic();
            general.setName("General");
            general.setIcon("help_outline_rounded");
            general.setBuilding(building);
            general.setQuestions(new ArrayList<>());

            FaqQuestion gQ1 = new FaqQuestion();
            gQ1.setQuestion("Urgence ?");
            gQ1.setAnswer("Contactez le gardien ou le numéro affiché.");
            gQ1.setTopic(general);
            general.getQuestions().add(gQ1);

            faqTopicRepository.save(general);
        });
    }

    /*   private void initializeOwnerTenantData() {
           if (leaseContractRepository.count() > 0) {
               log.info("Owner/Tenant data already initialized, skipping...");
               return;
           }

           log.info("Initializing Owner/Tenant test data...");

           Building buildingLiege = buildingRepository.findById("BEL-2024-DM-LIEGE").orElse(null);
           if (buildingLiege == null) {
               log.warn("Building not found, skipping owner/tenant initialization");
               return;
           }

           Resident owner1 = Resident.builder()
                   .idUsers(UUID.randomUUID().toString())
                   .fname("Pierre")
                   .lname("Dupont")
                   .email("pierre.dupont@owner.com")
                   .password(passwordEncoder.encode("owner123"))
                   .phoneNumber("+32470111222")
                   .role(UserRole.OWNER)
                   .accountStatus(AccountStatus.ACTIVE)
                   .isEnabled(true)
                   .isAccountNonExpired(true)
                   .isAccountNonLocked(true)
                   .isCredentialsNonExpired(true)
                   .build();
           owner1 = residentRepository.save(owner1);
           log.info("Created owner: Pierre Dupont (pierre.dupont@owner.com / owner123)");

           ResidentBuilding rbOwner1 = ResidentBuilding.builder()
                   .resident(owner1)
                   .building(buildingLiege)
                   .roleInBuilding(UserRole.OWNER)
                   .build();
           residentBuildingRepository.save(rbOwner1);

           Resident tenant1 = Resident.builder()
                   .idUsers(UUID.randomUUID().toString())
                   .fname("Marie")
                   .lname("Martin")
                   .email("marie.martin@tenant.com")
                   .password(passwordEncoder.encode("tenant123"))
                   .phoneNumber("+32470333444")
                   .role(UserRole.RESIDENT)
                   .accountStatus(AccountStatus.ACTIVE)
                   .isEnabled(true)
                   .isAccountNonExpired(true)
                   .isAccountNonLocked(true)
                   .isCredentialsNonExpired(true)
                   .build();
           tenant1 = residentRepository.save(tenant1);
           log.info("Created tenant: Marie Martin (marie.martin@tenant.com / tenant123)");

           Apartment apt101 = apartmentRepository.findById("BEL-2024-DM-LIEGE-A101").orElse(null);
           if (apt101 != null) {
               apt101.setOwner(owner1);
               apt101.setTenant(tenant1);
               apartmentRepository.save(apt101);

               ApartmentRoomLegacy room1 = ApartmentRoom.builder()
                       .apartmentId(apt101.getIdApartment())
                       .roomName("Salon")
                      // .roomType("living_room")
                       //.description("Grand salon lumineux avec baie vitrée")
                       .orderIndex(0)
                       .build();
               apartmentRoomLegacyRepository.save(room1);

               ApartmentRoomLegacy room2 = ApartmentRoom.builder()
                       .apartment(apt101)
                       .roomName("Chambre principale")
                       .roomType("bedroom")
                       .description("Chambre spacieuse avec placard intégré")
                       .orderIndex(1)
                       .build();
               apartmentRoomLegacyRepository.save(room2);

               ApartmentRoomLegacy room3 = ApartmentRoom.builder()
                       .apartment(apt101)
                       .roomName("Cuisine")
                       .roomType("kitchen")
                       .description("Cuisine équipée moderne")
                       .orderIndex(2)
                       .build();
               apartmentRoomLegacyRepository.save(room3);

               ApartmentRoomLegacy room4 = ApartmentRoom.builder()
                       .apartment(apt101)
                       .roomName("Salle de bain")
                       .roomType("bathroom")
                       .description("Salle de bain avec douche et baignoire")
                       .orderIndex(3)
                       .build();
               apartmentRoomLegacyRepository.save(room4);

               log.info("Created 4 rooms for apartment 101");

               LeaseContract contract1 = LeaseContract.builder()
                       .apartment(apt101)
                       .owner(owner1)
                       .tenant(tenant1)
                       .startDate(java.time.LocalDate.now())
                       .endDate(java.time.LocalDate.now().plusYears(9))
                       .initialRentAmount(new BigDecimal("950.00"))
                       .currentRentAmount(new BigDecimal("950.00"))
                       .depositAmount(new BigDecimal("1900.00"))
                       .chargesAmount(new BigDecimal("150.00"))
                       .regionCode("BE-BXL")
                       .status(LeaseContractStatus.DRAFT)
                       .build();
               contract1 = leaseContractRepository.save(contract1);
               log.info("Created lease contract for apartment 101");
   //
               ResidentBuilding rbTenant1 = ResidentBuilding.builder()
                       .resident(tenant1)
                       .building(buildingLiege)
                       .apartment(apt101)
                       .roleInBuilding(UserRole.RESIDENT)
                       .build();
               residentBuildingRepository.save(rbTenant1);
           }

           if (leaseContractArticleRepository.count() == 0) {
               initializeBrusselsLeaseArticles();
               log.info("Created standard lease contract articles for BE-BXL (Brussels)");
           }

           log.info("==================== OWNER/TENANT DATA INITIALIZED ====================");
           log.info("Test Owner: pierre.dupont@owner.com / owner123");
           log.info("Test Tenant: marie.martin@tenant.com / tenant123");
           log.info("Lease Contract created for apartment 101 (DRAFT status)");
           log.info("4 rooms created for apartment 101");
       }
   */

    private void initializeRoomTypes() {
        if (roomTypeRepository.count() > 0) {
            log.info("Room types already initialized, skipping...");
            return;
        }

        log.info("Initializing room types...");

        RoomType cuisine = new RoomType();
        cuisine.setName("Cuisine");
        cuisine.setBuildingId(null);
        cuisine = roomTypeRepository.save(cuisine);

        RoomTypeFieldDefinition cuisineEquipements = new RoomTypeFieldDefinition();
        cuisineEquipements.setRoomType(cuisine);
        cuisineEquipements.setFieldName("Équipements");
        cuisineEquipements.setFieldType(FieldType.EQUIPMENT_LIST);
        cuisineEquipements.setIsRequired(false);
        cuisineEquipements.setDisplayOrder(1);
        roomTypeFieldDefinitionRepository.save(cuisineEquipements);

        log.info("Room type 'Cuisine' created with field 'Équipements'");

        RoomType chambre = new RoomType();
        chambre.setName("Chambre à coucher");
        chambre.setBuildingId(null);
        chambre = roomTypeRepository.save(chambre);

        RoomTypeFieldDefinition chambreSurface = new RoomTypeFieldDefinition();
        chambreSurface.setRoomType(chambre);
        chambreSurface.setFieldName("Surface");
        chambreSurface.setFieldType(FieldType.NUMBER);
        chambreSurface.setIsRequired(false);
        chambreSurface.setDisplayOrder(1);
        roomTypeFieldDefinitionRepository.save(chambreSurface);

        RoomTypeFieldDefinition chambreImages = new RoomTypeFieldDefinition();
        chambreImages.setRoomType(chambre);
        chambreImages.setFieldName("Images");
        chambreImages.setFieldType(FieldType.IMAGE_LIST);
        chambreImages.setIsRequired(false);
        chambreImages.setDisplayOrder(2);
        roomTypeFieldDefinitionRepository.save(chambreImages);

        log.info("Room type 'Chambre à coucher' created with fields 'Surface' and 'Images'");

        RoomType salleEau = new RoomType();
        salleEau.setName("Salle d'eau");
        salleEau.setBuildingId(null);
        salleEau = roomTypeRepository.save(salleEau);

        RoomTypeFieldDefinition salleEauEquipements = new RoomTypeFieldDefinition();
        salleEauEquipements.setRoomType(salleEau);
        salleEauEquipements.setFieldName("Équipements");
        salleEauEquipements.setFieldType(FieldType.EQUIPMENT_LIST);
        salleEauEquipements.setIsRequired(false);
        salleEauEquipements.setDisplayOrder(1);
        roomTypeFieldDefinitionRepository.save(salleEauEquipements);

        RoomTypeFieldDefinition salleEauImages = new RoomTypeFieldDefinition();
        salleEauImages.setRoomType(salleEau);
        salleEauImages.setFieldName("Images");
        salleEauImages.setFieldType(FieldType.IMAGE_LIST);
        salleEauImages.setIsRequired(false);
        salleEauImages.setDisplayOrder(2);
        roomTypeFieldDefinitionRepository.save(salleEauImages);

        log.info("Room type 'Salle d'eau' created with fields 'Équipements' and 'Images'");

        log.info("==================== ROOM TYPES INITIALIZATION COMPLETE ====================");
        log.info("3 room types initialized:");
        log.info("  - Cuisine (with Équipements)");
        log.info("  - Chambre à coucher (with Surface, Images)");
        log.info("  - Salle d'eau (with Équipements, Images)");
    }

}