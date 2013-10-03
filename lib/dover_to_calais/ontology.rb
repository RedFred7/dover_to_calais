#  ontology.rb
#  
#  Copyright 2013 Fred <fred@fred-Veriton-X270>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  


module CalaisOntology
  CALAIS_ENTITIES = %w(
    Anniversary
    City
    Company
    Continent
    Country
    Currency
    EmailAddress
    EntertainmentAwardEvent
    Facility
    FaxNumber
    Holiday
    IndustryTerm
    MarketIndex
    MedicalCondition
    MedicalTreatment
    Movie
    MusicAlbum
    MusicGroup
    NaturalFeature
    OperatingSystem
    Organization
    Person
    PhoneNumber
    PoliticalEvent
    Product
    ProgrammingLanguage
    ProvinceOrState
    PublishedMedium
    RadioProgram
    RadioStation
    Region
    SportsEvent
    SportsGame
    SportsLeague
    TVShow
    TVStation
    Technology
    URL
  )

CALAIS_EVENTS = %w(
    Acquisition
    Alliance
    AnalystEarningsEstimate
    AnalystRecommendation
    Arrest
    Bankruptcy
    BonusSharesIssuance
    BusinessRelation
    Buybacks
    CompanyAccountingChange
    CompanyEarningsAnnouncement
    CompanyEarningsGuidance
    CompanyExpansion
    CompanyForceMajeure
    CompanyInvestment
    CompanyLaborIssues
    CompanyLayoffs
    CompanyLegalIssues
    CompanyListingChange
    CompanyMeeting
    CompanyNameChange
    CompanyReorganization
    CompanyRestatement
    ConferenceCall
    Conviction
    CreditRating
    DebtFinancing
    DelayedFiling
    DiplomaticRelations
    Dividend
    EmploymentChange
    EnvironmentalIssue
    Extinction
    FDAPhase
    Indictment
    IPO
    JointVenture
    ManMadeDisaster
    Merger
    MovieRelease
    MusicAlbumRelease
    NaturalDisaster
    PatentFiling
    PatentIssuance
    PersonTravel
    PoliticalEndorsement
    PoliticalRelationship
    PollsResult
    ProductIssues
    ProductRecall
    ProductRelease
    SocialTags
    SecondaryIssuance
    PersonCommunication
    StockSplit
    Trial
    VotingResult
)

CALAIS_TOPICS = %w(
    Business_Finance
    Disaster_Accident
    Education
    Entertainment_Culture
    Environment
    Health_Medical_Pharma
    Hospitality_Recreation
    Human_Interest
    Labor
    Law_Crime
    Politics
    Religion_Belief
    Social_Issues
    Sports
    Technology_Internet
    Weather
    War_Conflict
    Other
)

end

