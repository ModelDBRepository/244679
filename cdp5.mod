: Calcium ion accumulation with endogenous buffers, DCM and pump

COMMENT

The intracellular Ca2+ was modeled using the detailed Ca2+ dynamics model written by (Anwar et al., 2012). 
The model included a Ca2+Pump using Michaelis-Menten-Kinetics and two Ca2+ binding proteins:Parvalbumin and Calbindin D28-k.
 In this model we added two more Ca2+ binding proteins: a generic fast immobile buffer and the Ca2+ indicator used in the experiments. 
 The immobile buffer and the Ca2+ indicator are single-site binding molecules with equal association constant limited by diffusion (Canepari and Mammano, 1999).
 Diffusion was removed by the model. The empirical kinetic parameters for Parvalbumin (Lee et al., 2000) 
 and Calbindin D28-k (Nägerl et al., 2000) were corrected to take into account the physiological temperature by multiplying 
the Kon with a factor of 5 and buffer diffusion was corrected by multiplying the Calbindin concentration with a factor of 4.

Current Model Reference: Karima Ait Ouares , Luiza Filipis , Alexandra Tzilivaki , Panayiota Poirazi , Marco Canepari (2018) Two distinct sets of Ca 2+ and K + channels 
are activated at different membrane potential by the climbing fibre synaptic potential in Purkinje neuron dendrites. 

PubMed link: 

Contact: Filipis Luiza (luiza.filipis@univ-grenoble-alpes.fr)
ENDCOMMENT




NEURON {
  SUFFIX cdp5
  USEION ca READ cao, cai, ica WRITE cai
  RANGE ica_pmp,TotalPump,kpmp1, kpmp2, kpmp3
  RANGE Nannuli, Buffnull2, rf3, rf4, vrat
  RANGE  BTCnull, b1, b2, DMNPEnull, d1, d2, CBnull,nf1,nf2,ns1, ns2, PVnull, m1, m2, p1, p2
  

}


UNITS {
	(mol)   = (1)
	(molar) = (1/liter)
	(mM)    = (millimolar)
	(um)    = (micron)
	(mA)    = (milliamp)
	FARADAY = (faraday)  (10000 coulomb)
	PI      = (pi)       (1)
}

PARAMETER {
	Nannuli = 10.9495 (1)
	celsius (degC)
        
	cainull = 45e-6 (mM)
        mginull =.59    (mM)

:	values for a buffer compensating the diffusion
  
	Buffnull1 = 0	(mM)
	rf1 = 0.0134329	(/ms mM)
	rf2 = 0.0397469	(/ms)

	Buffnull2 = 60.9091	(mM)
	rf3 = 0.1435	(/ms mM)
	rf4 = 0.0014	(/ms)

:	values for benzothiazole coumarin (BTC)
	BTCnull = 1	(mM)
	b1 = 570	(/ms mM)
	b2 = 5.7	(/ms)
	

:	values for caged compound DMNPE-4
	DMNPEnull = 0	(mM)
	c1 = 5.63	(/ms mM)
	c2 = 0.107e-3	(/ms)

:       values for Calbindin (2 high and 2 low affinity binding sites)

        CBnull=	.16             (mM)
        nf1   =43.5           (/ms mM)
        nf2   =3.58e-2        (/ms)
        ns1   =5.5            (/ms mM)
        ns2   =0.26e-2        (/ms)

:       values for Parvalbumin

        PVnull  = .08           (mM)
        m1    = 1.07e2        (/ms mM)
        m2    = 9.5e-4                (/ms)
        p1    = 0.8           (/ms mM)
        p2    = 2.5e-2                (/ms)

  	kpmp1    = 3e-3       (/mM-ms)
  	kpmp2    = 1.75e-5   (/ms)
  	kpmp3    = 7.255e-5  (/ms)
	TotalPump = 1e-9	(mol/cm2)	

}

ASSIGNED {
	diam      (um)
	ica       (mA/cm2)
	ica_pmp   (mA/cm2)
	parea     (um)     : pump area per unit length
	parea2	  (um)
	cai       (mM)
	cao       (mM)
	mgi	(mM)
	vrat	(1)	
}

STATE {
	: ca[0] is equivalent to cai
	: ca[] are very small, so specify absolute tolerance
	: let it be ~1.5 - 2 orders of magnitude smaller than baseline level
	ca		(mM)
	mg		(mM)	<1e-7>
	
	Buff1		(mM)	
	Buff1_ca	(mM)

	Buff2		(mM)
	Buff2_ca	(mM)

	BTC		(mM)
	BTC_ca		(mM)

	DMNPE		(mM)
	DMNPE_ca	(mM)	

        CB		(mM)
        CB_f_ca		(mM)
        CB_ca_s		(mM)
        CB_ca_ca	(mM)

        PV		(mM)
        PV_ca		(mM)
        PV_mg		(mM)
	
	pump		(mol/cm2) <1e-15>
	pumpca		(mol/cm2) <1e-15>

}

BREAKPOINT {
	SOLVE state METHOD sparse
}

LOCAL factors_done

INITIAL {
		factors()

		ca = cainull
		mg = mginull
		
		Buff1 = ssBuff1()
		Buff1_ca = ssBuff1ca()

		Buff2 = ssBuff2()
		Buff2_ca = ssBuff2ca()

		BTC = ssBTC()
		BTC_ca = ssBTCca()		

		DMNPE = ssDMNPE()
		DMNPE_ca = ssDMNPEca()

		CB = ssCB( kdf(), kds())   
	        CB_f_ca = ssCBfast( kdf(), kds())
       	 	CB_ca_s = ssCBslow( kdf(), kds())
        	CB_ca_ca = ssCBca( kdf(), kds())

        	PV = ssPV( kdc(), kdm())
        	PV_ca = ssPVca(kdc(), kdm())
        	PV_mg = ssPVmg(kdc(), kdm())

		
  	parea = PI*diam
	parea2 = PI*(diam-0.2)
	ica = 0
	ica_pmp = 0
:	ica_pmp_last = 0
	pump = TotalPump
	pumpca = 0

}

PROCEDURE factors() {
        LOCAL r, dr2
        r = 1/2                : starts at edge (half diam)
        dr2 = r/(Nannuli-1)/2  : full thickness of outermost annulus,
        vrat = PI*(r-dr2/2)*2*dr2  : interior half
        r = r - dr2
}


LOCAL dsq, dsqvol  : cant define local variable in KINETIC block
                   :   or use in COMPARTMENT statement

KINETIC state {
  COMPARTMENT diam*diam*vrat {ca mg Buff1 Buff1_ca Buff2 Buff2_ca BTC BTC_ca DMNPE DMNPE_ca CB CB_f_ca CB_ca_s CB_ca_ca PV PV_ca PV_mg}
  COMPARTMENT (1e10)*parea {pump pumpca}
	:pump
	~ ca + pump <-> pumpca  (kpmp1*parea*(1e10), kpmp2*parea*(1e10))
	~ pumpca <-> pump   (kpmp3*parea*(1e10), 0)
  	CONSERVE pump + pumpca = TotalPump * parea * (1e10)
	
	ica_pmp = 2*FARADAY*(f_flux - b_flux)/parea	
	: all currents except pump
	: ica is Ca efflux
	~ ca << (-ica*PI*diam/(2*FARADAY))

	:RADIAL DIFFUSION OF ca, mg and mobile buffers

	dsq = diam*diam
		dsqvol = dsq*vrat
		~ ca + Buff1 <-> Buff1_ca (rf1*dsqvol, rf2*dsqvol)
		~ ca + Buff2 <-> Buff2_ca (rf3*dsqvol, rf4*dsqvol)
		~ ca + BTC <-> BTC_ca (b1*dsqvol, b2*dsqvol)
		~ ca + DMNPE <-> DMNPE_ca (c1*dsqvol, c2*dsqvol)
		:Calbindin	
		~ ca + CB <-> CB_ca_s (nf1*dsqvol, nf2*dsqvol)
	       	~ ca + CB <-> CB_f_ca (ns1*dsqvol, ns2*dsqvol)
        	~ ca + CB_f_ca <-> CB_ca_ca (nf1*dsqvol, nf2*dsqvol)
        	~ ca + CB_ca_s <-> CB_ca_ca (ns1*dsqvol, ns2*dsqvol)

		:Paravalbumin
        	~ ca + PV <-> PV_ca (m1*dsqvol, m2*dsqvol)
        	~ mg + PV <-> PV_mg (p1*dsqvol, p2*dsqvol)

  	cai = ca
	mgi = mg
}

FUNCTION ssBuff1() (mM) {
	ssBuff1 = Buffnull1/(1+((rf1/rf2)*cainull))
}
FUNCTION ssBuff1ca() (mM) {
	ssBuff1ca = Buffnull1/(1+(rf2/(rf1*cainull)))
}
FUNCTION ssBuff2() (mM) {
        ssBuff2 = Buffnull2/(1+((rf3/rf4)*cainull))
}
FUNCTION ssBuff2ca() (mM) {
        ssBuff2ca = Buffnull2/(1+(rf4/(rf3*cainull)))
}

FUNCTION ssBTC() (mM) {
	ssBTC = BTCnull/(1+((b1/b2)*cainull))
}

FUNCTION ssBTCca() (mM) {
	ssBTCca = BTCnull/(1+(b2/(b1*cainull)))
}

FUNCTION ssDMNPE() (mM) {
	ssDMNPE = DMNPEnull/(1+((c1/c2)*cainull))
}

FUNCTION ssDMNPEca() (mM) {
	ssDMNPEca = DMNPEnull/(1+(c2/(c1*cainull)))
}

FUNCTION ssCB( kdf(), kds()) (mM) {
	ssCB = CBnull/(1+kdf()+kds()+(kdf()*kds()))
}
FUNCTION ssCBfast( kdf(), kds()) (mM) {
	ssCBfast = (CBnull*kds())/(1+kdf()+kds()+(kdf()*kds()))
}
FUNCTION ssCBslow( kdf(), kds()) (mM) {
	ssCBslow = (CBnull*kdf())/(1+kdf()+kds()+(kdf()*kds()))
}
FUNCTION ssCBca(kdf(), kds()) (mM) {
	ssCBca = (CBnull*kdf()*kds())/(1+kdf()+kds()+(kdf()*kds()))
}
FUNCTION kdf() (1) {
	kdf = (cainull*nf1)/nf2
}
FUNCTION kds() (1) {
	kds = (cainull*ns1)/ns2
}
FUNCTION kdc() (1) {
	kdc = (cainull*m1)/m2
}
FUNCTION kdm() (1) {
	kdm = (mginull*p1)/p2
}
FUNCTION ssPV( kdc(), kdm()) (mM) {
	ssPV = PVnull/(1+kdc()+kdm())
}
FUNCTION ssPVca( kdc(), kdm()) (mM) {
	ssPVca = (PVnull*kdc())/(1+kdc()+kdm())
}
FUNCTION ssPVmg( kdc(), kdm()) (mM) {
	ssPVmg = (PVnull*kdm())/(1+kdc()+kdm())
}
