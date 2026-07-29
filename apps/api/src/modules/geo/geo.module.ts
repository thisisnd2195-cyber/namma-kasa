import { Module } from "@nestjs/common";
import { HouseholdMappingService } from "./household-mapping.service";

@Module({
  providers: [HouseholdMappingService],
  exports: [HouseholdMappingService],
})
export class GeoModule {}
