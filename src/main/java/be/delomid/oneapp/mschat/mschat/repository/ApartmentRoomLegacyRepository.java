package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.ApartmentRoomLegacy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ApartmentRoomLegacyRepository extends JpaRepository<ApartmentRoomLegacy, UUID> {
    List<ApartmentRoomLegacy> findByApartment_IdApartmentOrderByOrderIndex(String apartmentId);
}
