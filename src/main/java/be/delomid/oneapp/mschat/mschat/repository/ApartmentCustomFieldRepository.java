package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.ApartmentCustomField;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ApartmentCustomFieldRepository extends JpaRepository<ApartmentCustomField, Long> {
    List<ApartmentCustomField> findByApartmentIdOrderByDisplayOrder(String apartmentId);
}
