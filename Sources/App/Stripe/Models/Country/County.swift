//
//  County.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Node
import Vapor

public final class VerificationRequirement: NodeConvertible {
    
    public let minimum: [String]
    public let additional: [String]
    
    public init(node: Node) throws {
        minimum = try node.extract("minimum")
        additional = try node.extract("additional")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "minimum" : .array(minimum.map { Node.string($0) } ),
            "additional" : .array(minimum.map { Node.string($0) } )
        ] as [String : Node])
    }
}

public final class CountryVerificationFields: NodeConvertible {

    public let individual: VerificationRequirement
    public let company: VerificationRequirement

    public required init(node: Node) throws {
        individual = try node.extract("individual")
        company = try node.extract("company")
    }

    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "individual" : try individual.makeNode(in: context),
            "company" : try company.makeNode(in: context)
        ] as [String : Node])
    }
}

public enum CountryCode: String, NodeConvertible {
    case af
    case ax
    case al
    case dz
    case `as`
    case ad
    case ao
    case ai
    case aq
    case ag
    case ar
    case am
    case aw
    case au
    case at
    case az
    case bs
    case bh
    case bd
    case bb
    case by
    case be
    case bz
    case bj
    case bm
    case bt
    case bo
    case bq
    case ba
    case bw
    case bv
    case br
    case io
    case bn
    case bg
    case bf
    case bi
    case kh
    case cm
    case ca
    case cv
    case ky
    case cf
    case td
    case cl
    case cn
    case cx
    case cc
    case co
    case km
    case cg
    case cd
    case ck
    case cr
    case ci
    case hr
    case cu
    case cw
    case cy
    case cz
    case dk
    case dj
    case dm
    case `do`
    case ec
    case eg
    case sv
    case gq
    case er
    case ee
    case et
    case fk
    case fo
    case fj
    case fi
    case fr
    case gf
    case pf
    case tf
    case ga
    case gm
    case ge
    case de
    case gh
    case gi
    case gr
    case gl
    case gd
    case gp
    case gu
    case gt
    case gg
    case gn
    case gw
    case gy
    case ht
    case hm
    case va
    case hn
    case hk
    case hu
    case `is`
    case `in`
    case id
    case ir
    case iq
    case ie
    case im
    case il
    case it
    case jm
    case jp
    case je
    case jo
    case kz
    case ke
    case ki
    case kp
    case kr
    case kw
    case kg
    case la
    case lv
    case lb
    case ls
    case lr
    case ly
    case li
    case lt
    case lu
    case mo
    case mk
    case mg
    case mw
    case my
    case mv
    case ml
    case mt
    case mh
    case mq
    case mr
    case mu
    case yt
    case mx
    case fm
    case md
    case mc
    case mn
    case me
    case ms
    case ma
    case mz
    case mm
    case na
    case nr
    case np
    case nl
    case nc
    case nz
    case ni
    case ne
    case ng
    case nu
    case nf
    case mp
    case no
    case om
    case pk
    case pw
    case ps
    case pa
    case pg
    case py
    case pe
    case ph
    case pn
    case pl
    case pt
    case pr
    case qa
    case re
    case ro
    case ru
    case rw
    case bl
    case sh
    case kn
    case lc
    case mf
    case pm
    case vc
    case ws
    case sm
    case st
    case sa
    case sn
    case rs
    case sc
    case sl
    case sg
    case sx
    case sk
    case si
    case sb
    case so
    case za
    case gs
    case ss
    case es
    case lk
    case sd
    case sr
    case sj
    case sz
    case se
    case ch
    case sy
    case tw
    case tj
    case tz
    case th
    case tl
    case tg
    case tk
    case to
    case tt
    case tn
    case tr
    case tm
    case tc
    case tv
    case ug
    case ua
    case ae
    case gb
    case us
    case um
    case uy
    case uz
    case vu
    case ve
    case vn
    case vg
    case vi
    case wf
    case eh
    case ye
    case zm
    case zw

    public init(node: Node) throws {
        guard let value = node.string else {
            throw Abort.custom(status: .internalServerError, message: "Expected \(String.self) for country code")
        }

        guard let _self = CountryCode(rawValue: value.lowercased()) else {
            throw Abort.custom(status: .internalServerError, message: "Country code \(value.lowercased()) doesn't match any known codes.")
        }

        self = _self
    }
}
