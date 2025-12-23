package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Apartment;
import be.delomid.oneapp.mschat.mschat.model.ApartmentRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ApartmentRoomNewRepository extends JpaRepository<ApartmentRoom, Long> {
    List<ApartmentRoom> findByApartmentOrderById(Apartment apartment);

    @Query("SELECT ar FROM ApartmentRoom ar LEFT JOIN FETCH ar.roomType LEFT JOIN FETCH ar.fieldValues WHERE ar.apartment.idApartment = :apartmentId")
    List<ApartmentRoom> findByApartmentIdWithDetails(String apartmentId);
}
