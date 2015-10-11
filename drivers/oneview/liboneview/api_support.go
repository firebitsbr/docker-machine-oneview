package liboneview

import "strings"

// create a api support functions for each method that has new support
// check support should be used in test cases or functions to determine
// if a certain behavior is required for a given context.   For exmple:
// If we are making a call to profile_templates.go we should
// 1. ask if profile_templates needs supprt checks (use APISupportCheck.HasCheck)
// 2. if profile_templates needs support check, find out if the current lib Version
//    will support profile_templates or not : Check

// APISupport
type APISupport int

// Methods that require support
const (
	C_PROFILE_TEMPLATES APISupport = 1 + iota
	C_NONE
)

// apisupportlist - real names of things
var apisupportlist = [...]string{
	"profile_templates.go",
	"No Support Check Required",
}

// NewByName - returns a new APISupport by name
func (o APISupport) NewByName(name string) APISupport {
	return o.New(o.Get(name))
}

// New - returns a new APISupport object
func (o APISupport) New(i int) APISupport {
	var asc APISupport
	asc = APISupport(i)
	return asc
}

// IsSupported - given the current Version is there api support?
func (o APISupport) IsSupported(v Version) bool {
	switch o {
	case C_PROFILE_TEMPLATES:
		return API_VER2 == v
	default:
		return true
	}
}

// Integer get the int value for APISupport
func (o APISupport) Integer() int { return int(o) }

// String helper for state
func (o APISupport) String() string { return apisupportlist[o] }

// Equal helper for state
func (o APISupport) Equal(s string) bool {
	return (strings.ToUpper(s) == strings.ToUpper(o.String()))
}

// HasCheck - used to determine if we have to make an api verification check
func (o APISupport) HasCheck(s string) bool {
	for _, sc := range apisupportlist {
		if sc == s {
			return true
		}
	}
	return false
}

// Get - get an APISupport from string, returns C_NONE if not found
func (o APISupport) Get(s string) int {
	for i, sc := range apisupportlist {
		if sc == s {
			return i + 1
		}
	}
	return len(apisupportlist)
}
