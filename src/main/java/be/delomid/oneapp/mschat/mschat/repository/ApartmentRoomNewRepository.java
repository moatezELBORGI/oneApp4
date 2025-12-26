package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Apartment;
import be.delomid.oneapp.mschat.mschat.model.ApartmentRoom;
import be.delomid.oneapp.mschat.mschat.model.RoomEquipment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ApartmentRoomNewRepository extends JpaRepository<ApartmentRoom, Long> {
    List<ApartmentRoom> findByApartmentOrderById(Apartment apartment);

    @Query("SELECT DISTINCT ar FROM ApartmentRoom ar " +
            "LEFT JOIN FETCH ar.roomType " +
            "LEFT JOIN FETCH ar.images " +
            "WHERE ar.apartment.idApartment = :apartmentId " +
            "ORDER BY ar.id")
    List<ApartmentRoom> findByApartmentIdWithDetails(String apartmentId);

    @Query("SELECT DISTINCT ar FROM ApartmentRoom ar " +
            "LEFT JOIN FETCH ar.fieldValues " +
            "WHERE ar.id IN :roomIds")
    List<ApartmentRoom> findFieldValuesForRooms(List<Long> roomIds);

    @Query("SELECT DISTINCT ar FROM ApartmentRoom ar " +
            "LEFT JOIN FETCH ar.equipments " +
            "WHERE ar.id IN :roomIds")
    List<ApartmentRoom> findEquipmentsForRooms(List<Long> roomIds);

    @Query("SELECT DISTINCT re FROM RoomEquipment re " +
            "LEFT JOIN FETCH re.images " +
            "WHERE re.apartmentRoom.id IN :roomIds")
    List<RoomEquipment> findEquipmentImagesForRooms(List<Long> roomIds);
}
