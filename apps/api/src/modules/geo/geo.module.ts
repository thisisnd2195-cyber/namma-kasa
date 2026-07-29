import { Module } from "@nestjs/common";
import { AdminGeoController } from "./admin-geo.controller";
import { GeoRepository } from "./geo.repository";
import { HouseholdMappingService } from "./household-mapping.service";
import { HouseholdsService } from "./households.service";
import { OperatorsService } from "./operators.service";
import { RoutesService } from "./routes.service";
import { WardsService } from "./wards.service";

@Module({
  controllers: [AdminGeoController],
  providers: [
    GeoRepository,
    HouseholdMappingService,
    HouseholdsService,
    OperatorsService,
    RoutesService,
    WardsService,
  ],
  exports: [HouseholdMappingService, RoutesService, WardsService],
})
export class GeoModule {}
