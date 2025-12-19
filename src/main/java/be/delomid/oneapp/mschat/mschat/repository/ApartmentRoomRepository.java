package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.ApartmentRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ApartmentRoomRepository extends JpaRepository<ApartmentRoom, UUID> {
    List<ApartmentRoom> findByApartment_IdApartmentOrderByOrderIndex(String apartmentId);
}
